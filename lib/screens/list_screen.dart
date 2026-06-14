import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'employee_dashboard.dart';
import 'admin_dashboard.dart';

class ListScreen extends StatefulWidget {
  final String storeName;
  const ListScreen({Key? key, required this.storeName}) : super(key: key);

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<dynamic> allEmployees = [];
  List<dynamic> filteredEmployees = [];
  bool isLoading = true;
  String queryText = "";

  @override
  void initState() {
    super.initState();
    _fetchRoster();
  }

  void _fetchRoster() async {
    var data = await ApiService.getEmployees(widget.storeName);
    setState(() {
      allEmployees = data;
      filteredEmployees = data;
      isLoading = false;
    });
  }

  void _filterSearch(String text) {
    setState(() {
      queryText = text;
      filteredEmployees = allEmployees
          .where((emp) => emp['name'].toString().toLowerCase().contains(text.toLowerCase()) || 
                          emp['ep_number'].toString().toLowerCase().contains(text.toLowerCase()))
          .toList();
    });
  }

  void _challengeAccess(Map<String, dynamic>? employee, bool isAdmin) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdmin ? 'Admin Credentials Verification' : 'Access Authentication Pin'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: "Enter 4-digit passcode PIN"),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (isAdmin) {
                if (passwordController.text == "9999") { // System global Admin baseline override pin
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDashboard(storeName: widget.storeName)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access Denied')));
                }
              } else {
                var authed = await ApiService.loginEmployee(employee!['ep_number'], passwordController.text);
                if (authed != null) {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeDashboard(employeeProfile: authed)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Security PIN')));
                }
              }
            },
            child: const Text('Unlock'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            width: 180,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: TextField(
              onChanged: _filterSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search here...",
                hintStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                contentPadding: EdgeInsets.zero
              ),
            ),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Top Anchored System Administrator Console Button Entry Node
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('SYSTEM ADMINISTRATOR GATEWAY', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _challengeAccess(null, true),
                  ),
                ),
                const Divider(thickness: 1),
                ...filteredEmployees.map((emp) => Card(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: emp['photoUrl'].toString().startsWith('http') 
                        ? NetworkImage(emp['photoUrl']) 
                        : const AssetImage('assets/images/placeholder.png') as ImageProvider,
                    ),
                    title: Text(emp['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Employee ID: ${emp['ep_number']}'),
                    trailing: const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                    onTap: () => _challengeAccess(emp, false),
                  ),
                )).toList()
              ],
            ),
    );
  }
}