import 'dart:convert';
import 'dart:io';

/// Test script to check Supabase database structure
void main() async {
  print('🔍 Testing Supabase Database Structure...\n');

  const String supabaseUrl = 'https://vvnsludqdidnqpbzzgeb.supabase.co';
  const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2bnNsdWRxZGlkbnFwYnp6Z2ViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNDg3MjIsImV4cCI6MjA3MDcyNDcyMn0.aFtPK2qhVJw3z324PjuM-q7e5_4J55mgm7A2fqkLO3c';

  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 10);

  try {
    // Test 1: Check if users table exists
    print('📋 Checking users table...');
    final usersRequest = await client.getUrl(
      Uri.parse('$supabaseUrl/rest/v1/users?select=*&limit=1'),
    );
    usersRequest.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    usersRequest.headers.set('apikey', supabaseAnonKey);

    final usersResponse = await usersRequest.close();
    print('Users table status: ${usersResponse.statusCode}');

    if (usersResponse.statusCode == 200) {
      print('✅ Users table exists and is accessible');
    } else if (usersResponse.statusCode == 401) {
      print('⚠️ Users table exists but requires authentication (RLS enabled)');
    } else if (usersResponse.statusCode == 404) {
      print('❌ Users table does not exist');
    } else {
      final responseBody = await usersResponse.transform(utf8.decoder).join();
      print('⚠️ Unexpected response: ${usersResponse.statusCode}');
      print('Response: $responseBody');
    }

    // Test 2: Check if user_stats table exists
    print('\n📊 Checking user_stats table...');
    final statsRequest = await client.getUrl(
      Uri.parse('$supabaseUrl/rest/v1/user_stats?select=*&limit=1'),
    );
    statsRequest.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    statsRequest.headers.set('apikey', supabaseAnonKey);

    final statsResponse = await statsRequest.close();
    print('User_stats table status: ${statsResponse.statusCode}');

    if (statsResponse.statusCode == 200) {
      print('✅ User_stats table exists and is accessible');
    } else if (statsResponse.statusCode == 401) {
      print(
        '⚠️ User_stats table exists but requires authentication (RLS enabled)',
      );
    } else if (statsResponse.statusCode == 404) {
      print('❌ User_stats table does not exist');
    } else {
      final responseBody = await statsResponse.transform(utf8.decoder).join();
      print('⚠️ Unexpected response: ${statsResponse.statusCode}');
      print('Response: $responseBody');
    }

    // Test 3: Test authentication endpoint
    print('\n🔐 Testing authentication endpoint...');
    final authRequest = await client.postUrl(
      Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password'),
    );
    authRequest.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    authRequest.headers.set('apikey', supabaseAnonKey);
    authRequest.headers.set('Content-Type', 'application/json');

    // Add a test body (this will fail but tells us if the endpoint exists)
    authRequest.write(
      json.encode({'email': 'test@example.com', 'password': 'testpassword'}),
    );

    final authResponse = await authRequest.close();
    print('Auth endpoint status: ${authResponse.statusCode}');

    if (authResponse.statusCode == 400) {
      print(
        '✅ Auth endpoint is working (400 = invalid credentials, which is expected)',
      );
    } else if (authResponse.statusCode == 404) {
      print('❌ Auth endpoint not found');
    } else {
      final responseBody = await authResponse.transform(utf8.decoder).join();
      print(
        'Auth response: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}',
      );
    }
  } catch (e) {
    print('❌ Error during tests: $e');
  } finally {
    client.close();
  }

  print('\n💡 Next steps:');
  print(
    '1. If tables don\'t exist, run the updated_supabase_schema.sql in your Supabase SQL editor',
  );
  print('2. Make sure Row Level Security (RLS) is properly configured');
  print('3. Check that triggers are created for handling new user signups');
  print('4. Test authentication with the debug app');
}
