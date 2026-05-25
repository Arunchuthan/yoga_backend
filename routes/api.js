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
router.post('/employee/leave-request', async (req, res) => {
    const { ep_number, dates } = req.body;
    try {
        const employee = await Employee.findOne({ ep_number });
        if (!employee) return res.status(404).json({ message: 'Employee not found' });
        
        employee.leaveRequests.push({ dates, status: 'Pending' });
        await employee.save();
        res.json({ message: 'Leave request submitted successfully', employee });
    } catch (err) {
        res.status(500).json({ error: err.message });
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

module.exports = router;
