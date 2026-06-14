const express = require('express');
const router = express.Router();
const https = require('https');
const Store = require('../models/Store');
const Employee = require('../models/Employee');

// ─── SMS HELPER ───────────────────────────────────────────────────────────────
async function sendSMS(mobileNumber, message) {
  return new Promise((resolve, reject) => {
    const url = `https://www.fast2sms.com/dev/bulkV2?authorization=bsNYwFlrRM64DumZToCBq3X9dSxnPjU2571Izcegh8GHJOyatVB9njfK8MGCSqyRhu56XdvPsiJ7EQxU&message=${encodeURIComponent(message)}&language=english&route=q&numbers=${mobileNumber}`;
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', reject);
  });
}

// ─── GET ALL STORES ───────────────────────────────────────────────────────────
router.get('/stores', async (req, res) => {
  try {
    const stores = await Store.find();
    res.json(stores);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── GET EMPLOYEES BY STORE ───────────────────────────────────────────────────
router.get('/employees/:storeName', async (req, res) => {
  try {
    const employees = await Employee.find({ storeName: req.params.storeName });
    res.json(employees);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── EMPLOYEE LOGIN ───────────────────────────────────────────────────────────
router.post('/employee/login', async (req, res) => {
  const { ep_number, password } = req.body;
  try {
    const employee = await Employee.findOne({ ep_number });
    if (!employee || employee.password !== password) {
      return res.status(401).json({ message: 'Invalid Credentials' });
    }
    res.json(employee);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── GET EMPLOYEE PROFILE (for dashboard refresh without password) ─────────────
router.get('/employee/profile/:ep_number', async (req, res) => {
  try {
    const employee = await Employee.findOne({ ep_number: req.params.ep_number });
    if (!employee) return res.status(404).json({ error: 'Employee not found' });
    res.json(employee);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── SUBMIT LEAVE REQUEST ─────────────────────────────────────────────────────
router.post('/employee/leave-request', async (req, res) => {
  try {
    let { ep_number, dates } = req.body;

    console.log(`📡 Incoming request for Employee: "${ep_number}" with Dates:`, dates);

    if (!ep_number || !dates) {
      return res.status(400).json({ success: false, message: 'Missing ep_number or dates' });
    }

    const cleanEpNumber = ep_number.trim();

    const employee = await Employee.findOne({
      ep_number: { $regex: new RegExp(`^${cleanEpNumber}$`, 'i') }
    });

    if (!employee) {
      console.log(`❌ MongoDB look-up failed for: "${cleanEpNumber}"`);
      return res.status(404).json({ success: false, message: `Employee '${cleanEpNumber}' not found` });
    }

    console.log(`🎯 Found Employee: ${employee.name}`);

    const newLeaveRequest = {
      dates: Array.isArray(dates) ? dates : [dates],
      status: 'Pending',
      createdAt: new Date()
    };

    if (!Array.isArray(employee.leaveRequests)) {
      employee.leaveRequests = [];
    }

    employee.leaveRequests.push(newLeaveRequest);
    await employee.save({ validateBeforeSave: false });

    console.log(`✅ Leave request saved for ${employee.name}`);
    return res.status(200).json({ success: true, message: 'Leave request submitted successfully' });

  } catch (err) {
    console.error('💥 CRITICAL BACKEND ERROR:', err);
    return res.status(500).json({ success: false, error: err.message });
  }
});

// ─── GET ALL PENDING LEAVE REQUESTS (Admin) ───────────────────────────────────
router.get('/admin/leave-requests', async (req, res) => {
  try {
    const employees = await Employee.find({ 'leaveRequests.status': 'Pending' });
    let summary = [];
    employees.forEach(emp => {
      emp.leaveRequests.forEach(req => {
        if (req.status === 'Pending') {
          summary.push({
            requestId: req._id,
            ep_number: emp.ep_number,
            name: emp.name,
            dates: req.dates,
            mobileNumber: emp.mobileNumber || emp.phone_number
          });
        }
      });
    });
    res.json(summary);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── PROCESS LEAVE REQUEST (Approve / Deny) ───────────────────────────────────
router.post('/admin/leave-process', async (req, res) => {
  try {
    const { ep_number, requestId, status } = req.body;

    const employee = await Employee.findOne({ ep_number });
    if (!employee) return res.status(404).json({ success: false, message: 'Employee not found' });

    // Find leave request by _id safely
    const leaveRequest = employee.leaveRequests.find(
      lr => lr._id.toString() === requestId.toString()
    );
    if (!leaveRequest) return res.status(404).json({ success: false, message: 'Leave request not found' });

    // Update status
    leaveRequest.status = status;

    // If approved, mark dates as Approved Leave in attendance
    if (status === 'Approved') {
      for (const date of leaveRequest.dates) {
        employee.attendance = employee.attendance.filter(a => a.date !== date);
        employee.attendance.push({ date: date, status: 'Approved Leave' });
      }
    }

    await employee.save({ validateBeforeSave: false });

    // Send SMS notification
    try {
      const dates = leaveRequest.dates.join(', ');
      const message = status === 'Approved'
        ? `Dear ${employee.name}, your leave request for ${dates} has been Approved by your manager.`
        : `Dear ${employee.name}, your leave request for ${dates} has been Denied by your manager.`;
      await sendSMS(employee.mobileNumber, message);
      console.log(`✅ SMS sent to ${employee.mobileNumber}`);
    } catch (smsErr) {
      console.log('SMS failed but leave status updated:', smsErr.message);
    }

    return res.status(200).json({ success: true, message: `Leave ${status} successfully` });

  } catch (err) {
    console.error('leave-process error:', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── SUBMIT DAILY ATTENDANCE ──────────────────────────────────────────────────
router.post('/admin/attendance', async (req, res) => {
  try {
    const { records, date } = req.body;
    for (const rec of records) {
      const employee = await Employee.findOne({ ep_number: rec.ep_number });
      if (!employee) continue;

      // Remove existing entry for this date to avoid duplicates
      employee.attendance = employee.attendance.filter(a => a.date !== date);

      // Push fresh record
      employee.attendance.push({ date: date, status: rec.status });
      await employee.save({ validateBeforeSave: false });
    }
    res.json({ success: true, message: 'Attendance records saved successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── ADD SINGLE EMPLOYEE ──────────────────────────────────────────────────────
router.post('/admin/add-employee', async (req, res) => {
  try {
    const newEmp = new Employee(req.body);
    await newEmp.save();
    res.json({ message: 'Employee profile saved successfully', newEmp });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── BULK IMPORT EMPLOYEES ────────────────────────────────────────────────────
router.post('/admin/bulk-import', async (req, res) => {
  const { employees } = req.body;
  try {
    await Employee.insertMany(employees, { ordered: false });
    res.json({ message: 'Bulk import completed' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;