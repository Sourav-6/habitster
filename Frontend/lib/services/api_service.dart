// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/chat_message.dart';
import 'profile_service.dart';

class ApiService {
// Appwrite client and account instance

  // CORRECT: Define _baseUrl INSIDE the class
  static const String _baseUrl = 'http://10.0.2.2:3000/api';

// --- NEW: Secure Storage ---
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'jwt_token'; // Key to store the token under

  // Method to save the token
  Future<void> _saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> saveToken(String token) async {
    await _saveToken(token);
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

  Future<void> loginWithGoogleToken(String token) async {
    await _saveToken(token);
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
        await ProfileService.setEmail(email);
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

  Future<Map<String, dynamic>> createHabit(
      Map<String, dynamic> habitData) async {
    final Uri habitsUri = Uri.parse('$_baseUrl/habits');

    try {
      final headers = await _getAuthHeaders(); // Get headers with token
      final response = await http.post(
        habitsUri,
        headers: headers, // Use authenticated headers
        body: json.encode(habitData),
      );

      if (response.statusCode == 201) {
        // Habit creation returns 201
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to create habit (Status code: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (e is Exception &&
          e.toString().startsWith('Exception: Failed to create habit')) {
        rethrow;
      }
      throw Exception('Network error or server unreachable: $e');
    }
  }

  Future<List<dynamic>> getHabits() async {
    // Returns a List
    final Uri habitsUri = Uri.parse('$_baseUrl/habits');

    try {
      final headers = await _getAuthHeaders(); // Get headers with token
      final response = await http.get(
        habitsUri,
        headers: headers, // Use authenticated headers
      );

      if (response.statusCode == 200) {
        // Backend sends back a List directly
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception(
            'Failed to load habits (Status code: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (e is Exception &&
          e.toString().startsWith('Exception: Failed to load habits')) {
        rethrow;
      }
      throw Exception('Network error or server unreachable: $e');
    }
  }

  Future<Map<String, dynamic>> createSubtask(
      Map<String, dynamic> subtaskData) async {
    final Uri subtasksUri = Uri.parse('$_baseUrl/subtasks');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        subtasksUri,
        headers: headers,
        body: json.encode(subtaskData),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to create subtask (Status code: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      // ... error handling ...
      rethrow;
    }
  }

  Future<List<dynamic>> getSubtasks(String habitId) async {
    // Returns a List
    // Construct the URL with the habitId
    final Uri subtasksUri = Uri.parse('$_baseUrl/habits/$habitId/subtasks');

    try {
      final headers = await _getAuthHeaders(); // Get headers with token
      final response = await http.get(
        subtasksUri,
        headers: headers, // Use authenticated headers
      );

      if (response.statusCode == 200) {
        // Backend sends back a List directly
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception(
            'Failed to load subtasks for habit $habitId (Status code: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (e is Exception &&
          e.toString().startsWith('Exception: Failed to load subtasks')) {
        rethrow;
      }
      throw Exception(
          'Network error or server unreachable fetching subtasks: $e');
    }
  }

  Future<Map<String, dynamic>> completeHabit(
      String habitId, List<String> completedSubtaskIds,
      {String? notes}) async {
    // Construct the URL
    final Uri completeUri = Uri.parse('$_baseUrl/habits/$habitId/complete');

    try {
      final headers = await _getAuthHeaders(); // Get headers with token
      // Prepare the body
      final Map<String, dynamic> body = {
        'completedSubtaskIds': completedSubtaskIds,
      };
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      final response = await http.post(
        completeUri,
        headers: headers, // Use authenticated headers
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        // Expect 200 OK on success
        return json.decode(response.body); // Return updated habit data
      } else {
        // Try to parse error details from Appwrite/backend
        String errorMessage = 'Failed to complete habit';
        try {
          final errorBody = json.decode(response.body);
          errorMessage = errorBody['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = response.body; // Fallback to raw body
        }
        throw Exception(
            'Failed to complete habit (Status code: ${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      if (e is Exception &&
          e.toString().startsWith('Exception: Failed to complete habit')) {
        rethrow;
      }
      throw Exception(
          'Network error or server unreachable during completion: $e');
    }
  }

  Future<Map<String, dynamic>> hideHabit(String habitId) async {
    final Uri hideUri = Uri.parse('$_baseUrl/habits/$habitId/hide');
    try {
      final headers = await _getAuthHeaders();
      headers.remove(
          'Content-Type'); // PUT might not need content-type if body is empty
      final response = await http.put(hideUri, headers: headers); // Use PUT
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to hide habit: ${response.body}');
      }
    } catch (e) {
      /* ... error handling ... */ rethrow;
    }
  }

  Future<Map<String, dynamic>> showHabit(String habitId) async {
    final Uri showUri = Uri.parse('$_baseUrl/habits/$habitId/show');
    try {
      final headers = await _getAuthHeaders();
      headers.remove('Content-Type');
      final response = await http.put(showUri, headers: headers); // Use PUT
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to show habit: ${response.body}');
      }
    } catch (e) {
      /* ... error handling ... */ rethrow;
    }
  }

  Future<List<dynamic>> getHiddenHabits() async {
    final Uri hiddenUri = Uri.parse('$_baseUrl/habits/hidden');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(hiddenUri, headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load hidden habits: ${response.body}');
      }
    } catch (e) {
      /* ... error handling ... */ rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTodaysHabitHistory(String habitId) async {
    final Uri historyUri = Uri.parse('$_baseUrl/habits/$habitId/history/today');
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(historyUri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return null; // No history found for today is not an error here
      } else {
        throw Exception('Failed to load today\'s history: ${response.body}');
      }
    } catch (e) {
      /* ... error handling ... */ rethrow;
    }
  }

  Future<String> sendMessageToAgent(String message) async {
    final Uri uri = Uri.parse('$_baseUrl/agent/chat');

    final headers = await _getAuthHeaders();
    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({'message': message}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['reply'];
    } else {
      throw Exception('Agent failed');
    }
  }

  Future<String> sendMessageToAgentWithContext(
    String message,
    List<ChatMessage> context,
  ) async {
    final uri = Uri.parse('$_baseUrl/agent/chat');
    final headers = await _getAuthHeaders();

    final body = {
      'message': message,
      'context': context
          .map((m) => {
                'role': m.role,
                'text': m.text,
              })
          .toList(),
    };

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['reply'];
    } else {
      throw Exception('Agent error: ${response.body}');
    }
  }

  Future<String?> getProactiveMessage() async {
    final uri = Uri.parse('$_baseUrl/agent/proactive');
    final headers = await _getAuthHeaders();

    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 204) return null;

    final data = json.decode(res.body);
    return data['message'];
  }

  Future<List<dynamic>> getHabitHistory(String habitId) async {
    // Returns a List
    final Uri historyUri = Uri.parse('$_baseUrl/habits/$habitId/history');

    try {
      final headers = await _getAuthHeaders(); // Get headers with token
      final response = await http.get(
        historyUri,
        headers: headers, // Use authenticated headers
      );

      if (response.statusCode == 200) {
        // Backend sends back a List of history documents
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception(
            'Failed to load history for habit $habitId (Status code: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (e is Exception &&
          e.toString().startsWith('Exception: Failed to load history')) {
        rethrow;
      }
      throw Exception(
          'Network error or server unreachable fetching history: $e');
    }
  }
}
