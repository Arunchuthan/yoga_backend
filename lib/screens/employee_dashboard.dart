import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'leave_request_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  final Map<String, dynamic> employeeProfile;
  const EmployeeDashboard({Key? key, required this.employeeProfile}) : super(key: key);

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  late Map<String, dynamic> currentProfile;
  int present = 0, absent = 0, doubleAbsent = 0, salaryDays = 0;
  List<dynamic> currentActiveRequests = [];
  bool _isLoadingFreshData = false;

  @override
  void initState() {
    super.initState();
    currentProfile = widget.employeeProfile;
    _crunchNumbers();
  }

  // FIX: Use getEmployeeProfile instead of loginEmployee.
  // loginEmployee requires the password, but we don't store passwords in the profile
  // map after login (and shouldn't). getEmployeeProfile fetches by ep_number only.
  Future<void> _refreshDashboardData() async {
    setState(() => _isLoadingFreshData = true);
    try {
      final epNumber = currentProfile['ep_number']?.toString() ?? '';
      if (epNumber.isEmpty) return;

      var freshData = await ApiService.getEmployeeProfile(epNumber);
      if (freshData != null && mounted) {
        setState(() {
          currentProfile = freshData;
        });
      }
    } catch (e) {
      print('Refresh failed: $e');
    } finally {
      if (mounted) {
        _crunchNumbers();
        setState(() => _isLoadingFreshData = false);
      }
    }
  }

  void _crunchNumbers() {
    var attendanceList = currentProfile['attendance'] as List? ?? [];
    present = attendanceList.where((at) => at['status'] == 'Present').length;
    absent = attendanceList.where((at) => at['status'] == 'Absent').length;
    doubleAbsent = attendanceList.where((at) => at['status'] == 'Double Absent').length;
    salaryDays = present - (doubleAbsent * 2);

    var rawRequests = currentProfile['leaveRequests'] as List? ?? [];
    DateTime now = DateTime.now();
    DateTime todayMidnight = DateTime(now.year, now.month, now.day);

    setState(() {
      currentActiveRequests = rawRequests.where((req) {
        var dateList = req['dates'] as List? ?? [];
        if (dateList.isEmpty) return false;
        try {
          DateTime lastDate = DateTime.parse(dateList.last.toString());
          return lastDate.isAfter(todayMidnight) || lastDate.isAtSameMomentAs(todayMidnight);
        } catch (_) {
          return false;
        }
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    var attendanceList = currentProfile['attendance'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${currentProfile['name'] ?? 'Employee'} - Console'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshDashboardData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingFreshData) const LinearProgressIndicator(color: Colors.indigo),
              const SizedBox(height: 10),
              const Text('Attendance Calendar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 30,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  int day = index + 1;
                  Color bg = Colors.grey[300]!;
                  Color textColor = Colors.black87;

                  // FIX: Use try/catch + manual scan instead of firstWhere with orElse: () => null,
                  // which causes a Dart type error on non-nullable lists in newer Flutter versions.
                  Map<String, dynamic>? dayRecord;
                  for (var record in attendanceList) {
                    try {
                      DateTime d = DateTime.parse(record['date'].toString());
                      if (d.day == day) {
                        dayRecord = record as Map<String, dynamic>;
                        break;
                      }
                    } catch (_) {}
                  }

                  if (dayRecord != null) {
                    String status = dayRecord['status'] ?? '';
                    if (status == 'Present') {
                      bg = Colors.green[500]!;
                      textColor = Colors.white;
                    } else if (status == 'Absent') {
                      bg = Colors.red[500]!;
                      textColor = Colors.white;
                    } else if (status == 'Double Absent') {
                      bg = Colors.black;
                      textColor = Colors.white;
                    } else if (status == 'Approved Leave') {
                      bg = Colors.amber[600]!;
                      textColor = Colors.white;
                    }
                  }

                  return Container(
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                    child: Center(child: Text('$day', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricItem('Present', present, Colors.green),
                          _buildMetricItem('Absent', absent, Colors.red),
                          _buildMetricItem('Double Abs', doubleAbsent, Colors.black),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        'Payable Salary Days: $salaryDays',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Active Leave Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              currentActiveRequests.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('No upcoming leave requests.', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentActiveRequests.length,
                      itemBuilder: (context, index) {
                        final req = currentActiveRequests[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today, color: Colors.indigo),
                            title: Text('Dates: ${(req['dates'] as List).join(", ")}'),
                            trailing: Chip(
                              label: Text(req['status'] ?? 'Pending'),
                              backgroundColor: req['status'] == 'Approved'
                                  ? Colors.green[100]
                                  : (req['status'] == 'Denied' ? Colors.red[100] : Colors.amber[100]),
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LeaveRequestScreen(epNumber: currentProfile['ep_number'].toString()),
                      ),
                    );
                    // Refresh after returning so the new request shows up immediately
                    _refreshDashboardData();
                  },
                  child: const Text('APPLY LEAVE REQUEST', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, int value, Color color) {
    return Column(
      children: [
        Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
