import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://yoga-backend-wau5.onrender.com/api';
  static const Duration _timeoutDuration = Duration(seconds: 35);

  static Future<List<dynamic>> getStores() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stores')).timeout(_timeoutDuration);
      return response.statusCode == 200 ? json.decode(response.body) as List : [];
    } catch (e) {
      print('getStores error: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getEmployees(String storeName) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/employees/${Uri.encodeComponent(storeName.trim())}'))
          .timeout(_timeoutDuration);
      return response.statusCode == 200 ? json.decode(response.body) as List : [];
    } catch (e) {
      print('getEmployees error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> loginEmployee(String epNumber, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employee/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ep_number': epNumber, 'password': password}),
      ).timeout(_timeoutDuration);
      return response.statusCode == 200 ? json.decode(response.body) as Map<String, dynamic> : null;
    } catch (e) {
      print('loginEmployee error: $e');
      return null;
    }
  }

  // FIX: New method to fetch fresh profile data without needing the password again.
  // Call this from the employee dashboard whenever you need to refresh attendance/leave data.
  // Make sure your backend has a GET /employee/profile/:ep_number route that returns the full profile.
  static Future<Map<String, dynamic>?> getEmployeeProfile(String epNumber) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/employee/profile/${Uri.encodeComponent(epNumber)}'))
          .timeout(_timeoutDuration);
      return response.statusCode == 200 ? json.decode(response.body) as Map<String, dynamic> : null;
    } catch (e) {
      print('getEmployeeProfile error: $e');
      return null;
    }
  }

  static Future<bool> submitLeave(String epNumber, List<String> dates) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employee/leave-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ep_number': epNumber, 'dates': dates}),
      ).timeout(_timeoutDuration);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('submitLeave error: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getAdminLeaveRequests() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/admin/leave-requests'))
          .timeout(_timeoutDuration);
      return response.statusCode == 200 ? json.decode(response.body) as List : [];
    } catch (e) {
      print('getAdminLeaveRequests error: $e');
      return [];
    }
  }

  static Future<bool> processLeaveRequest(String epNumber, String requestId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/leave-process'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ep_number': epNumber, 'requestId': requestId, 'status': status}),
      ).timeout(_timeoutDuration);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('processLeaveRequest error: $e');
      return false;
    }
  }

  static Future<bool> submitDailyAttendance(List<Map<String, String>> records, String date) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/attendance'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'records': records, 'date': date}),
      ).timeout(_timeoutDuration);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('submitDailyAttendance error: $e');
      return false;
    }
  }

  static Future<bool> addSingleEmployee(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/add-employee'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      ).timeout(_timeoutDuration);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('addSingleEmployee error: $e');
      return false;
    }
  }

  static Future<bool> bulkUploadEmployees(List<Map<String, dynamic>> employeeList) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/bulk-import'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'employees': employeeList}),
      ).timeout(_timeoutDuration);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('bulkUploadEmployees error: $e');
      return false;
    }
  }
}
