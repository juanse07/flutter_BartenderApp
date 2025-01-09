import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8888';
  
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

  Future<void> updateQuotationState(String id, String newState) async {
  try {
    print('� Attempting to update quotation state');
    print('� Quotation ID: $id');
    print('� New State: $newState');
    print('� Endpoint: ${baseUrl}/bar-service-quotations/$id');

    final requestBody = {'state': newState};
    print('� Request Body: ${jsonEncode(requestBody)}');

    final response = await http.patch(
      Uri.parse('${baseUrl}/bar-service-quotations/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    print('� Response Status Code: ${response.statusCode}');
    print('� Response Body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ Quotation state updated successfully');
      return;
    }

    // Log error details if status code is not 200
    print('⚠️ Error: Non-200 status code received');
    print('⚠️ Status Code: ${response.statusCode}');
    print('⚠️ Response Body: ${response.body}');
    
    throw Exception(
      'Failed to update quotation state. Status: ${response.statusCode}, Body: ${response.body}'
    );
  } catch (e) {
    print('❌ Failed to update quotation state');
    print('❌ Error details: $e');
    print('❌ Stack trace: ${StackTrace.current}');
    throw e;
  }
}

  Future<List<dynamic>> getQuotationsWithDebugbyState({String? state}) async {
    try {
      // Build the URL with the optional `state` query parameter
      final uri = Uri.parse('$baseUrl/bar-service-quotations')
          .replace(queryParameters: state != null ? {'state': state} : null);

      print('Attempting to connect to: $uri');

      final response = await http.get(
        uri,
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
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response received');
        }
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Connection error: $e');
      rethrow;
    }
  }


}