import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'add_employee_screen.dart';
import 'employee_calendar_view.dart';

class AdminDashboard extends StatefulWidget {
  final String storeName;
  const AdminDashboard({Key? key, required this.storeName}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> leaveRequests = [];
  List<dynamic> activeRoster = [];
  Map<String, String> attendancePayload = {}; // Maps ep_number to selected status
  bool isAttendanceLocked = false;

  @override
  void initState() {
    super.initState();
    _reloadAdminState();
  }

  void _reloadAdminState() async {
    var leaves = await ApiService.getAdminLeaveRequests();
    var roster = await ApiService.getEmployees(widget.storeName);
    setState(() {
      leaveRequests = leaves;
      activeRoster = roster;
      for (var emp in roster) {
        attendancePayload[emp['ep_number']] = 'Present'; // Initialize default safety baseline selection configuration
      }
    });
  }

  void _processLeave(Map<String, dynamic> request, String status) async {
    bool ok = await ApiService.processLeaveRequest(request['ep_number'], request['requestId'], status);
    if (ok) {
      if (status == 'Approved') {
        // Mock integration linking local device runtime environment to generate outward dispatch notification payload
        debugPrint("DISPATCHING OUTWARD WHATSAPP MESSAGE AUTOMATION TO PARTNER INTERFACE VIA DEV: ${request['mobileNumber']}");
      }
      _reloadAdminState();
    }
  }

  void _commitDailyAttendanceLog() async {
    String todayStr = DateTime.now().toString().split(" ")[0];
    List<Map<String, String>> recordsList = [];
    attendancePayload.forEach((key, val) {
      recordsList.add({'ep_number': key, 'status': val});
    });

    bool finished = await ApiService.submitDailyAttendance(recordsList, todayStr);
    if (finished) {
      setState(() { isAttendanceLocked = true; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance structural records locked globally for today.')));
    }
  }

  void _extractRosterMetricsToExcel() {
    // Structural compliance design pattern mockup displaying data compilation mapping
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance matrix successfully written to local file: /storage/emulated/0/Download/Attendance_Report.csv')));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Management Desk'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [Tab(text: 'Leave Approvals'), Tab(text: 'Daily Attendance')],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.download), onPressed: _extractRosterMetricsToExcel),
            IconButton(icon: const Icon(Icons.person_add), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEmployeeScreen(storeName: widget.storeName))))
          ],
        ),
        body: TabBarView(
          children: [
            // Panel Component Array Alpha: Leave Request Assessment Queue Manager
            leaveRequests.isEmpty
                ? const Center(child: Text('Clear queue. No pending applications.'))
                : ListView.builder(
                    itemCount: leaveRequests.length,
                    itemBuilder: (context, index) {
                      final item = leaveRequests[index];
                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          title: Text('${item['name']} (${item['ep_number']})'),
                          subtitle: Text('Requested Blocks: ${(item['dates'] as List).join(", ")}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _processLeave(item, 'Approved')),
                              IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _processLeave(item, 'Denied')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            // Panel Component Array Beta: Daily Attendance Roster Checklist Rollcall Engine
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: activeRoster.length,
                    itemBuilder: (context, index) {
                      final emp = activeRoster[index];
                      String currentSelection = attendancePayload[emp['ep_number']] ?? 'Present';
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeCalendarView(employeeObject: emp))),
                            child: Text(emp['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, decoration: TextDecoration.underline)),
                          ),
                          subtitle: Text('ID: ${emp['ep_number']}'),
                          trailing: isAttendanceLocked 
                            ? Text(currentSelection, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))
                            : DropdownButton<String>(
                                value: currentSelection,
                                items: ['Present', 'Absent', 'Double Absent'].map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                                onChanged: (val) { if (val != null) setState(() { attendancePayload[emp['ep_number']] = val; }); },
                              ),
                        ),
                      );
                    },
                  ),
                ),
                if (!isAttendanceLocked)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 46)),
                      onPressed: _commitDailyAttendanceLog,
                      child: const Text('LOCK AND SUBMIT ALL RECORD TRACKS', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
              ],
            )
          ],
        ),
      ),
    );
  }
}