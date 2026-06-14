import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaveRequestScreen extends StatefulWidget {
  final String epNumber;
  const LeaveRequestScreen({Key? key, required this.epNumber}) : super(key: key);

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final List<DateTime> _selectedDates = [];
  bool _isSending = false; // Tracks network transmission states to prevent double taps

  void _onDaySelected(DateTime date) {
    DateTime pureDate = DateTime(date.year, date.month, date.day);
    setState(() {
      if (_selectedDates.contains(pureDate)) {
        _selectedDates.remove(pureDate);
      } else {
        // Enforce strict local structural validation constraints criteria layout
        if (_selectedDates.length >= 6) {
          _showAlert("Limit Exceeded", "You cannot apply for more than 6 days of leave in a month.");
          return;
        }
        _selectedDates.add(pureDate);
        _selectedDates.sort();

        // Scan array matrix to block more than three continuous sequences
        int continuousCount = 1;
        for (int i = 0; i < _selectedDates.length - 1; i++) {
          if (_selectedDates[i + 1].difference(_selectedDates[i]).inDays == 1) {
            continuousCount++;
            if (continuousCount > 3) {
              _selectedDates.remove(pureDate);
              _showAlert("Policy Validation Failure", "Continuous block leave window cannot exceed 3 consecutive days.");
              return;
            }
          } else {
            continuousCount = 1;
          }
        }
      }
    });
  }

  void _showAlert(String title, String desc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(desc),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  // Handles data transmission to Admin database and handles navigation fallback routing
void _transmitLeaveApplication() async {
    // 1. Check if dates are actually selected
    if (_selectedDates.isEmpty) {
      _showAlert("Empty Field", "Please map at least one calendar date entry prior to execution.");
      return;
    }

    // 2. Print a log BEFORE setting the UI state to make sure the button works
    print("🚀 APPLY NOW clicked! Employee Number is: '${widget.epNumber}'");

    try {
      setState(() => _isSending = true);

      List<String> formattedDates = _selectedDates.map((d) => d.toString().split(" ")[0]).toList();
      print("📅 Formatted dates to send: $formattedDates");

      // 3. Trigger the network call
      print("📡 Attempting to contact Render server...");
      bool success = await ApiService.submitLeave(widget.epNumber, formattedDates);
      print("📥 Server responded. Success status: $success");
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leave proposal transmitted to Admin Dashboard successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          setState(() => _isSending = false); 
          _showAlert("Network Error", "Failed to forward request to Admin portal. Please check connection.");
        }
      }
    } catch (error, stacktrace) {
      // 💥 THIS WILL CATCH THE SILENT CRASH AND FORCE IT INTO YOUR VS CODE TERMINAL
      print("💥 CRITICAL UI CRASH DETECTED:");
      print("Error: $error");
      print("Stacktrace: $stacktrace");
      if (mounted) {
        setState(() => _isSending = false);
        _showAlert("Internal Error", "An internal application error occurred: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    
    // Configures how many total days into the future are visible to the employee
    const int totalDisplayDays = 8; // Today + next 7 days rolling forward

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Leave Window'), 
        backgroundColor: Colors.indigo, 
        foregroundColor: Colors.white
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'SELECT AVAILABLE LEAVE DATES', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            const SizedBox(height: 6),
            const Text(
              'Showing today and the next 7 days rolling window timeline',
              style: TextStyle(color: Colors.grey, fontSize: 12)
            ),
            const SizedBox(height: 16),
            
            // High efficiency custom interaction grid engine
            Expanded(
              child: GridView.builder(
                itemCount: totalDisplayDays, 
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 responsive grid cells per line looks great on mobile screens
                  mainAxisSpacing: 10, 
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1
                ),
                itemBuilder: (context, index) {
                  // Generates the date sequentially starting exactly from today's dynamic date!
                  // Index 0 = May 25, Index 1 = May 26... moving smoothly across calendar months
                  DateTime targetDay = today.add(Duration(days: index));
                  
                  bool isSelected = _selectedDates.contains(targetDay);
                  String dayNum = targetDay.day.toString();
                  String monthName = _getMonthAbbreviation(targetDay.month);

                  return GestureDetector(
                    onTap: (!_isSending) ? () => _onDaySelected(targetDay) : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.indigo : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.indigo : Colors.indigo.withOpacity(0.2),
                          width: 1.5
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2)
                          )
                        ]
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            monthName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayNum,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87, 
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSending ? Colors.grey : Colors.green, 
                foregroundColor: Colors.white, 
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              onPressed: _isSending ? null : _transmitLeaveApplication,
              child: _isSending 
                ? const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Text('APPLY NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  // Simple clean helper method to convert integers into clear textual calendar headers
  String _getMonthAbbreviation(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }
}