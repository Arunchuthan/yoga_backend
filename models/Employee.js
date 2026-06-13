const mongoose = require('mongoose');

const LeaveRequestSchema = new mongoose.Schema({
    dates: [{ type: String }],
    status: { type: String, enum: ['Pending', 'Approved', 'Denied'], default: 'Pending' },
    createdAt: { type: Date, default: Date.now }
});

const AttendanceSchema = new mongoose.Schema({
    date: { type: String, required: true },
    status: { type: String, enum: ['Present', 'Absent', 'Double Absent', 'Approved Leave'], required: true }
});

const EmployeeSchema = new mongoose.Schema({
    name: { type: String, required: true },
    ep_number: { type: String, required: true, unique: true },
    mobileNumber: { type: String, required: true },
    photoUrl: { type: String, required: true },
    storeName: { type: String, required: true },
    password: { type: String, required: true, default: '1234' },
    attendance: [AttendanceSchema],
    leaveRequests: [LeaveRequestSchema]
});

module.exports = mongoose.model('Employee', EmployeeSchema);
