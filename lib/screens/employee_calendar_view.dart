import 'package:flutter/material.dart';

class EmployeeCalendarView extends StatelessWidget {
  final Map<String, dynamic> employeeObject;
  const EmployeeCalendarView({Key? key, required this.employeeObject}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var attendanceList = employeeObject['attendance'] as List? ?? [];

    int p = attendanceList.where((a) => a['status'] == 'Present').length;
    int a = attendanceList.where((a) => a['status'] == 'Absent').length;
    int da = attendanceList.where((a) => a['status'] == 'Double Absent').length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${employeeObject['name'].toString().trim()} - History'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EP Number: ${employeeObject['ep_number']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              itemCount: 30,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4,
              ),
              itemBuilder: (context, idx) {
                int dayNum = idx + 1;
                Color tileBackground = Colors.grey[300]!;
                Color textColor = Colors.black87;

                // FIX: Manual scan instead of firstWhere with orElse: () => null.
                // In Dart, List<dynamic>.firstWhere with a nullable orElse causes a
                // runtime type error. A for-loop is safe and explicit.
                Map<String, dynamic>? dayRecord;
                for (var record in attendanceList) {
                  try {
                    DateTime recordDate = DateTime.parse(record['date'].toString());
                    if (recordDate.day == dayNum) {
                      dayRecord = record as Map<String, dynamic>;
                      break;
                    }
                  } catch (_) {}
                }

                if (dayRecord != null) {
                  String status = dayRecord['status'] ?? '';
                  if (status == 'Present') {
                    tileBackground = Colors.green[500]!;
                    textColor = Colors.white;
                  } else if (status == 'Absent') {
                    tileBackground = Colors.red[500]!;
                    textColor = Colors.white;
                  } else if (status == 'Double Absent') {
                    tileBackground = Colors.black;
                    textColor = Colors.white;
                  } else if (status == 'Approved Leave') {
                    tileBackground = Colors.amber[600]!;
                    textColor = Colors.white;
                  }
                }

                return Container(
                  decoration: BoxDecoration(color: tileBackground, borderRadius: BorderRadius.circular(4)),
                  child: Center(
                    child: Text('$dayNum', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Present: $p', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Absent: $a', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Double Abs: $da', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Spacer(),
            const Center(
              child: Text(
                '⚠️ Direct adjustment of leave records is restricted.',
                style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
