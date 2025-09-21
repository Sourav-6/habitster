import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // For Android Emulator, use 10.0.2.2. For iOS Simulator/Web, use localhost.
  static const String _baseUrl = 'http://10.0.2.2:3000/api';

  Future<Map<String, dynamic>> registerUser(String email, String password) async {
    // 1. Define the full URL for the endpoint
    final Uri registerUri = Uri.parse('$_baseUrl/auth/register');

    try {
      // 2. Create the body of the request (the data we're sending)
      final Map<String, String> body = {
        'email': email,
        'password': password,
      };

      // 3. Make the POST request
      final response = await http.post(
        registerUri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(body),
      );

      // 4. Check the response status code
      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON.
        return json.decode(response.body);
      } else {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        throw Exception('Failed to register user: ${response.body}');
      }
    } catch (e) {
      // 5. Handle any errors that occur during the request
      throw Exception('Failed to connect to the server: $e');
    }
  }

  // Login function is still a placeholder
  // lib/services/api_service.dart

// ... (ApiService class and registerUser function are above this)

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final Uri loginUri = Uri.parse('$_baseUrl/auth/login');

    try {
      final response = await http.post(
        loginUri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to log in: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }
}