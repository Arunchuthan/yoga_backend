const express = require('express');
const router = express.Router();
const Store = require('../models/Store');
const Employee = require('../models/Employee');

// Fetch all retail stores
router.get('/stores', async (req, res) => {
    try {
        const stores = await Store.find();
        res.json(stores);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Fetch all employees assigned to a specific store
router.get('/employees/:storeName', async (req, res) => {
    try {
        const employees = await Employee.find({ storeName: req.params.storeName });
        res.json(employees);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Authenticate employee access profile
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

// Submit a single leave application request
// Submit a single leave application request
// Submit a single leave application request
router.post('/employee/leave-request', async (req, res) => {
    try {
        let { ep_number, dates } = req.body;

        console.log(`📡 Incoming request for Employee: "${ep_number}" with Dates:`, dates);

        if (!ep_number || !dates) {
            return res.status(400).json({ success: false, message: 'Missing ep_number or dates' });
        }

        const cleanEpNumber = ep_number.trim();

        // FAIL-SAFE LOOKUP: Case-insensitive match to handle any string format perfectly
        const employee = await Employee.findOne({ 
            ep_number: { $regex: new RegExp(`^${cleanEpNumber}$`, 'i') } 
        });

        if (!employee) {
            console.log(`❌ MongoDB look-up failed for: "${cleanEpNumber}"`);
            return res.status(404).json({ success: false, message: `Employee profile '${cleanEpNumber}' not found` });
        }

        console.log(`🎯 Found Employee profile document: ${employee.name}`);

        // Construct the subdocument precisely
        const newLeaveRequest = {
            dates: Array.isArray(dates) ? dates : [dates],
            status: 'Pending',
            createdAt: new Date()
        };

        // If leaveRequests array doesn't exist or failed to initialize, create it manually
        if (!Array.isArray(employee.leaveRequests)) {
            employee.leaveRequests = [];
        }

        // Push directly into the schema matrix array
        employee.leaveRequests.push(newLeaveRequest);
        
        // Save to MongoDB Atlas
       await employee.save({ validateBeforeSave: false });
        
        console.log(`✅ Leave array successfully updated for ${employee.name}`);
        return res.status(200).json({ 
            success: true, 
            message: 'Leave request submitted successfully'
        });

    } catch (err) {
        console.error("💥 CRITICAL BACKEND ERROR:", err);
        return res.status(500).json({ success: false, error: err.message });
    }
});
// Fetch all active global pending leave requests for Admin
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
                        mobileNumber: emp.mobileNumber || emp.phone_number // Fallback safety
                    });
                }
            });
        });
        res.json(summary);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Process a pending leave request (Approve or Deny status updates)
router.post('/admin/leave-process', async (req, res) => {
    const { ep_number, requestId, status } = req.body;
    try {
        const employee = await Employee.findOne({ ep_number });
        if (!employee) {
            return res.status(404).json({ success: false, message: 'Employee not found' });
        }
        
        const request = employee.leaveRequests.id(requestId);
        if (!request) {
            return res.status(404).json({ success: false, message: 'Request not found' });
        }
        
        // 1. Update the request track status
        request.status = status;
        
        // 2. If approved, add dates directly to attendance map logs for the dashboard calendar grid
        if (status === 'Approved') {
            request.dates.forEach(date => {
                const alreadyLogged = employee.attendance.some(att => att.date === date);
                if (!alreadyLogged) {
                    employee.attendance.push({ 
                        date: date, 
                        status: 'Approved Leave' 
                    });
                }
            });
        }
        
        await employee.save();
        
        // Return a response body that matches exactly what Flutter's ApiService expects
        return res.status(200).json({ 
            success: true, 
            message: `Leave status updated to ${status}`, 
            employee 
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ success: false, error: err.message });
    }
});

// Submit complete collective daily roster attendance data
router.post('/admin/attendance', async (req, res) => {
    const { records, date } = req.body; // records: [{ ep_number, status }]
    try {
        for (let rec of records) {
            const employee = await Employee.findOne({ ep_number: rec.ep_number });
            if (employee) {
                const existing = employee.attendance.find(att => att.date === date);
                if (!existing) {
                    employee.attendance.push({ date, status: rec.status });
                    await employee.save();
                }
            }
        }
        res.json({ message: 'Attendance records permanently locked for the date' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Register a single new profile record
router.post('/admin/add-employee', async (req, res) => {
    try {
        const newEmp = new Employee(req.body);
        await newEmp.save();
        res.json({ message: 'Employee profile saved successfully', newEmp });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET profile by EP number (used for dashboard refresh without password)
router.get('/employee/profile/:ep_number', async (req, res) => {
  try {
    const employee = await Employee.findOne({ ep_number: req.params.ep_number });
    if (!employee) return res.status(404).json({ error: 'Employee not found' });
    res.json(employee);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
// Bulk Import data pipeline from CSV records
router.post('/admin/bulk-import', async (req, res) => {
    const { employees } = req.body; 
    try {
        await Employee.insertMany(employees, { ordered: false });
        res.json({ message: 'Bulk batch insertion operation completed' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.post('/admin/leave-process', async (req, res) => {
  try {
    const { ep_number, requestId, status } = req.body;

    const employee = await Employee.findOne({ ep_number: ep_number });
    if (!employee) return res.status(404).json({ error: 'Employee not found' });

    // FIX: Find by _id using toString() comparison instead of .id() method
    const leaveRequest = employee.leaveRequests.find(
      lr => lr._id.toString() === requestId.toString()
    );
    
    if (!leaveRequest) return res.status(404).json({ error: 'Leave request not found' });

    leaveRequest.status = status;

    // FIX: Also update attendance if Approved
    if (status === 'Approved') {
      for (const date of leaveRequest.dates) {
        // Remove existing entry for this date
        employee.attendance = employee.attendance.filter(a => a.date !== date);
        // Add as Approved Leave
        employee.attendance.push({ date: date, status: 'Approved Leave' });
      }
    }

    await employee.save({ validateBeforeSave: false });
    res.json({ success: true, message: `Leave ${status}` });
  } catch (err) {
    console.error('leave-process error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ✅ PASTE HERE - Attendance Submit Route
router.post('/admin/attendance', async (req, res) => {
  try {
    const { records, date } = req.body;
    for (const record of records) {
      const employee = await Employee.findOne({ ep_number: record.ep_number });
      if (!employee) continue;

      // Remove existing entry for this date if any
      employee.attendance = employee.attendance.filter(a => a.date !== date);

      // Push new record
      employee.attendance.push({ date: date, status: record.status });
      await employee.save({ validateBeforeSave: false });
    }
    res.json({ success: true, message: 'Attendance saved' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router; // this line already exists, don't add it twice
