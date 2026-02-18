// lib/services/market_history_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kisan_veer/models/market_models.dart';
import 'package:intl/intl.dart';

class MarketHistoryService {
  final String _baseUrl =
      'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070'; // AGMARKNET API base URL
    // https://script.google.com/macros/s/AKfycbx7bWOZ45Z7NUc4YQu05bio8gBk3lMNf6kqDHKyAY3dU8Rv49Xm9UkZeAoI3Gy1dk-dNA/exec

  // Fetch historical market data
  Future<List<MarketRecord>> fetchHistoricalData({
    required String commodity,
    String? state,
    String? district,
    String? market,
    int days = 30,
  }) async {
    try {
      final queryParams = {
        'action': 'getData',
        'commodity': commodity,
        'days': days.toString(),
      };

      if (state != null) queryParams['state'] = state;
      if (district != null) queryParams['district'] = district;
      if (market != null) queryParams['market'] = market;

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['records'] != null) {
          return (data['records'] as List).map((record) {
            return MarketRecord(
              state: record['state'] ?? '',
              district: record['district'] ?? '',
              market: record['market'] ?? '',
              commodity: record['commodity'] ?? '',
              variety: record['variety'] ?? '',
              grade: record['grade'] ?? '',
              arrivalDate: _parseDate(record['arrival_date'] ?? record['date']),
              minPrice: _parseDouble(
                  record['min_x0020_price'] ?? record['min_price']),
              maxPrice: _parseDouble(
                  record['max_x0020_price'] ?? record['max_price']),
              modalPrice: _parseDouble(
                  record['modal_x0020_price'] ?? record['modal_price']),
              quantity:
                  _parseDouble(record['arrival_qty'] ?? record['quantity']),
              arrivalQuantity: _parseDouble(
                  record['arrival_quantity'] ?? record['arrival_qty'] ?? 0),
            );
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error fetching historical market data: $e');
      throw Exception('Failed to fetch historical market data: $e');
    }
  }

  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now();
    }

    try {
      // First try YYYY-MM-DD format
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Then try DD/MM/YYYY format (AGMARKNET format)
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[1]), // month
            int.parse(parts[0]), // day
          );
        }
      } catch (_) {
        // Fall back to current date
      }
      return DateTime.now();
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
