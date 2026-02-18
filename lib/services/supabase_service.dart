import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> getpaymentApiKey(String keyName) async {
    final response = await _supabase
        .from('secrets')
        .select('key_value')
        .eq('key_name', 'razorpay_key')
        .single();

    return response['key_value'] as String?;
  }

  // Add alias for consistent naming
  Future<String?> getPaymentApiKey(String keyName) async {
    return getpaymentApiKey(keyName);
  }
}
