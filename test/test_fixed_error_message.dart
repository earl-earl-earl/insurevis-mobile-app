import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/services/supabase_service.dart';
import '../lib/config/supabase_config.dart';

void main() async {
  print('🧪 Testing Fixed Error Message...\n');

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Test signup with valid data
  print('📝 Testing signup to see new error message...');

  final testEmail =
      'fixed_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
  print('Using test email: $testEmail');

  final result = await SupabaseService.signUp(
    name: 'Test User',
    email: testEmail,
    password: 'TestPassword123!',
    phone: '+1234567890',
  );

  print('\n📋 Signup Result:');
  print('Success: ${result['success']}');
  print('Message: ${result['message']}');

  if (result['success'] == false) {
    print('\n✅ Expected behavior:');
    if (result['message'].toString().contains('email verification failed')) {
      print('🎯 SUCCESS! Now showing proper email error message');
      print('Instead of generic "Failed to create account"');
    } else {
      print('⚠️ Still showing generic error: ${result['message']}');
    }
  } else {
    print('\n🎉 Signup actually worked! Email issue might be resolved');
  }

  exit(0);
}
