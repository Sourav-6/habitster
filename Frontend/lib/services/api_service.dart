// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // CORRECT: Define _baseUrl INSIDE the class
  static const String _baseUrl = 'http://10.0.2.2:3000/api';

// --- NEW: Secure Storage ---
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'jwt_token'; // Key to store the token under

  // Method to save the token
  Future<void> _saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Method to get the token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Method to delete the token (for logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Helper to get authenticated headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> registerUser(
      String email, String password) async {
    // CORRECT: Use _baseUrl here
    final Uri registerUri = Uri.parse('$_baseUrl/auth/register');

    try {
      final response = await http.post(
        registerUri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to register user (Status code: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (e is Exception &&
          e.toString().startsWith('Exception: Failed to register user')) {
        rethrow;
      }
      throw Exception('Network error or server unreachable: $e');
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    // CORRECT: Use _baseUrl here
    final Uri loginUri = Uri.parse('$_baseUrl/auth/login');

    try {
      final response = await http.post(
        loginUri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['token'] != null) {
          await _saveToken(data['token']); // <-- Save the token on login
          // Optional debug print
        }
        return data;
      } else {
        throw Exception(
            'Failed to log in (Status code: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (e is Exception &&
          e.toString().startsWith('Exception: Failed to log in')) {
        rethrow;
      }
      throw Exception('Network error or server unreachable: $e');
    }
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData) async {
    // CORRECT: Use _baseUrl here
    final Uri tasksUri = Uri.parse('$_baseUrl/tasks');

    try {
      final headers = await _getAuthHeaders(); // <-- Get headers with token
      final response = await http.post(
        tasksUri,
        headers: headers, // <-- Use authenticated headers
        body: json.encode(taskData),
      );

      if (response.statusCode == 201) {
        // Task creation returns 201
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to create task (Status code: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (e is Exception &&
          e.toString().startsWith('Exception: Failed to create task')) {
        rethrow;
      }
      throw Exception('Network error or server unreachable: $e');
    }
  }
  // lib/services/api_service.dart

// ... (createTask function is above this)

  Future<List<dynamic>> getTasks() async {
    // Returns a List
    final Uri tasksUri = Uri.parse('$_baseUrl/tasks');

    try {
      // Note: We need to handle authentication later to send a token
      final headers = await _getAuthHeaders(); // <-- Get headers with token
      final response = await http.get(
        tasksUri,
        headers: headers, // <-- Use authenticated headers
      );

      if (response.statusCode == 200) {
        // The backend sends back a List directly
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception(
            'Failed to load tasks (Status code: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (e is Exception &&
          e.toString().startsWith('Exception: Failed to load tasks')) {
        rethrow;
      }
      throw Exception('Network error or server unreachable: $e');
    }
  }

  // lib/services/api_service.dart

// ... (getTasks function is above this)

  Future<void> deleteTask(String taskId) async {
    // No return value needed for delete
    // Construct the URL with the taskId
    final Uri deleteUri = Uri.parse('$_baseUrl/tasks/$taskId');

    try {
      final headers = await _getAuthHeaders(); // <-- Get headers with token
      // Remove Content-Type for DELETE if backend doesn't expect it
      headers.remove('Content-Type');
      final response = await http.delete(
        deleteUri,
        headers: headers, // <-- Use authenticated headers
      );

      // Standard success code for DELETE is 204 No Content
      if (response.statusCode == 204) {
        return; // Success
      } else {
        // Handle potential errors like 404 Not Found or others
        throw Exception(
            'Failed to delete task (Status code: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (e is Exception &&
          e.toString().startsWith('Exception: Failed to delete task')) {
        rethrow;
      }
      throw Exception('Network error or server unreachable: $e');
    }
  }

  Future<Map<String, dynamic>> updateTask(
      String taskId, Map<String, dynamic> updateData) async {
    // Construct the URL with the taskId
    final Uri updateUri = Uri.parse('$_baseUrl/tasks/$taskId');

    try {
      final headers = await _getAuthHeaders(); // <-- Get headers with token
      final response = await http.put(
        updateUri,
        headers: headers, // <-- Use authenticated headers
        body: json.encode(updateData),
      );
      // Standard success code for PUT is 200 OK
      if (response.statusCode == 200) {
        return json.decode(response.body); // Return the updated task
      } else {
        throw Exception(
            'Failed to update task (Status code: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (e is Exception &&
          e.toString().startsWith('Exception: Failed to update task')) {
        rethrow;
      }
      throw Exception('Network error or server unreachable: $e');
    }
  }
}
