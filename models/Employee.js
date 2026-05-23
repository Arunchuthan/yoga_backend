const mongoose = require('mongoose');

const LeaveRequestSchema = new mongoose.Schema({
    dates: [{ type: String }], // ISO format string: 'YYYY-MM-DD'
    status: { type: String, enum: ['Pending', 'Approved', 'Denied'], default: 'Pending' },
    createdAt: { type: Date, default: Date.now }
});

const AttendanceSchema = new mongoose.Schema({
    date: { type: String, required: true }, // Format: 'YYYY-MM-DD'
    status: { type: String, enum: ['Present', 'Absent', 'Double Absent'], required: true }
});

const EmployeeSchema = new mongoose.Schema({
    name: { type: String, required: true },
    ep_number: { type: String, required: true, unique: true },
    mobileNumber: { type: String, required: true },
    photoUrl: { type: String, required: true }, // Image URL or Base64 string
    storeName: { type: String, required: true }, // 'YOGA SUPER MART', 'YOGA SAREES', 'YOGA SILKS'
    password: { type: String, required: true, default: '1234' }, // Simple default setup passcode
    attendance: [AttendanceSchema],
    leaveRequests: [LeaveRequestSchema]
});

module.exports = mongoose.model('Employee', EmployeeSchema);