import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/services/supabase_service.dart';
import '../lib/config/supabase_config.dart';

void main() async {
  print('🔍 Testing Signup Error...\n');

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Test signup with valid data
  print('📝 Testing signup with valid data...');

  final testEmail = 'test${DateTime.now().millisecondsSinceEpoch}@example.com';
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
    print('\n❌ Error Details:');
    print('Message: ${result['message']}');

    // Check if it's a server error
    final message = result['message'].toString().toLowerCase();
    if (message.contains('server') || message.contains('unexpectedly')) {
      print('\n🔍 This appears to be a server error. Common causes:');
      print('1. Database table missing or improperly configured');
      print('2. Row Level Security (RLS) blocking insert operations');
      print('3. Database trigger failures');
      print('4. Network connectivity issues');
      print('5. Supabase project configuration issues');
    }
  } else {
    print('\n✅ Signup successful!');
    print('User ID: ${result['user']?.id}');
    print(
      'Requires email verification: ${result['requiresEmailVerification']}',
    );
  }

  exit(0);
}
