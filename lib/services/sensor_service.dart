import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SensorService {
  static final String _supabaseUrl = dotenv.env['SUPABASE_URL']!;
  static final String _apiKey = dotenv.env['SUPABASE_ANON_KEY']!;
  static const String _table = 'sensor_data';

  /// Fetch the latest sensor data (most recent row)
  static Future<Map<String, dynamic>?> fetchLatestSensorData() async {
    final url = Uri.parse('$_supabaseUrl/rest/v1/$_table?order=created_at.desc&limit=1');
    final response = await http.get(
      url,
      headers: {
        'apikey': _apiKey,
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List && data.isNotEmpty) {
        return data.first as Map<String, dynamic>;
      }
      return null;
    }
    throw Exception('Failed to fetch latest sensor data');
  }

  /// Fetch the last [count] sensor data records (for history/graph)
  static Future<List<Map<String, dynamic>>> fetchSensorHistory({int count = 10}) async {
    final url = Uri.parse('$_supabaseUrl/rest/v1/$_table?order=created_at.desc&limit=$count');
    final response = await http.get(
      url,
      headers: {
        'apikey': _apiKey,
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    }
    throw Exception('Failed to fetch sensor history');
  }
}
