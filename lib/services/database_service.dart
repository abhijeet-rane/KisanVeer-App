import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch all products
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      final response = await _client.from('products').select();
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  /// Add a new product
  Future<void> addProduct(Map<String, dynamic> product) async {
    try {
      await _client.from('products').insert(product);
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }
}
