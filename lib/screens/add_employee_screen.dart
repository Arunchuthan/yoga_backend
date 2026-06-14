import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddEmployeeScreen extends StatefulWidget {
  final String storeName;
  const AddEmployeeScreen({Key? key, required this.storeName}) : super(key: key);

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '', epNumber = '', mobile = '';

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      Map<String, dynamic> newStaff = {
        'name': name,
        'ep_number': epNumber,
        'mobileNumber': mobile,
        'photoUrl': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150', // Automated design baseline placeholder assignment rule configuration map
        'storeName': widget.storeName
      };

      bool done = await ApiService.addSingleEmployee(newStaff);
      if (done) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile created successfully')));
        Navigator.pop(context);
      }
    }
  }

  void _triggerBulkCSVImport() async {
    // Demonstration processing engine mock illustrating execution pattern pipeline for CSV datasets string configuration logic conversion blocks
    List<Map<String, dynamic>> mockBulkData = [
      {'name': 'Bulk Staff Alpha', 'ep_number': 'EP-B1', 'mobileNumber': '9876543210', 'photoUrl': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150', 'storeName': widget.storeName},
      {'name': 'Bulk Staff Beta', 'ep_number': 'EP-B2', 'mobileNumber': '9876543211', 'photoUrl': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150', 'storeName': widget.storeName}
    ];

    bool bulkDone = await ApiService.bulkUploadEmployees(mockBulkData);
    if (bulkDone) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV operational datasets batch migration injection task completed')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Profile Node Record'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(decoration: const InputDecoration(labelText: 'Full Registered Name'), validator: (v) => v!.isEmpty ? 'Required' : null, onSaved: (v) => name = v!),
              TextFormField(decoration: const InputDecoration(labelText: 'Employee ID (EP Number)'), validator: (v) => v!.isEmpty ? 'Required' : null, onSaved: (v) => epNumber = v!),
              TextFormField(decoration: const InputDecoration(labelText: 'Mobile Communication Number'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null, onSaved: (v) => mobile = v!),
              const SizedBox(height: 24),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white), onPressed: _saveForm, child: const Text('COMMIT PROFILE REGISTER')),
              const SizedBox(height: 12),
              OutlinedButton.icon(icon: const Icon(Icons.file_present), label: const Text('BULK INJECT ARCHIVE VIA CSV DATASET'), onPressed: _triggerBulkCSVImport)
            ],
          ),
        ),
      ),
    );
  }
}