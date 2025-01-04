import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = process.env.API_URL;
  
  Future<List<dynamic>> getQuotationsWithDebug() async {
    try {
      print('Attempting to connect to: $baseUrl/bar-service-quotations');
      
      final response = await http.get(
        Uri.parse('$baseUrl/bar-service-quotations'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response received');
        }
        
        try {
          final data = json.decode(response.body) as List;
          print('Successfully decoded data: ${data.length} items');
          return data;
        } on FormatException catch (e) {
          print('JSON decode error: $e');
          throw Exception('Invalid response format: $e');
        }
      } else {
        print('Error status code: ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Connection error: $e');
      rethrow;
    }
  }
}