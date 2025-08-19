import 'dart:convert';
import 'dart:io';

/// Test script to check if Supabase database tables exist and are properly configured
void main() async {
  print('🔍 Checking Supabase Database Schema...\n');

  const String supabaseUrl = 'https://vvnsludqdidnqpbzzgeb.supabase.co';
  const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2bnNsdWRxZGlkbnFwYnp6Z2ViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNDg3MjIsImV4cCI6MjA3MDcyNDcyMn0.aFtPK2qhVJw3z324PjuM-q7e5_4J55mgm7A2fqkLO3c';

  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 10);

  try {
    print('1️⃣ Testing users table access...');
    await testTableAccess(client, supabaseUrl, supabaseAnonKey, 'users');

    print('\n2️⃣ Testing user_stats table access...');
    await testTableAccess(client, supabaseUrl, supabaseAnonKey, 'user_stats');

    print('\n3️⃣ Testing authentication signup endpoint...');
    await testSignupEndpoint(client, supabaseUrl, supabaseAnonKey);
  } catch (e) {
    print('❌ Error during tests: $e');
  } finally {
    client.close();
  }

  print('\n💡 **Recommendations:**');
  print('1. Go to your Supabase dashboard → SQL Editor');
  print('2. Run the updated_supabase_schema.sql script');
  print('3. Make sure Row Level Security (RLS) is properly configured');
  print('4. Check that the triggers for new user creation are working');
}

Future<void> testTableAccess(
  HttpClient client,
  String supabaseUrl,
  String supabaseAnonKey,
  String tableName,
) async {
  try {
    final request = await client.getUrl(
      Uri.parse('$supabaseUrl/rest/v1/$tableName?select=*&limit=1'),
    );
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('apikey', supabaseAnonKey);

    final response = await request.close();

    switch (response.statusCode) {
      case 200:
        print('✅ $tableName table exists and is accessible');
        break;
      case 401:
        print(
          '⚠️ $tableName table exists but requires authentication (RLS enabled)',
        );
        break;
      case 404:
        print('❌ $tableName table does not exist - NEEDS TO BE CREATED');
        break;
      case 406:
        final responseBody = await response.transform(utf8.decoder).join();
        if (responseBody.contains('schema')) {
          print('❌ $tableName table has schema issues');
        } else {
          print('⚠️ $tableName table access issue: $responseBody');
        }
        break;
      default:
        final responseBody = await response.transform(utf8.decoder).join();
        print('⚠️ $tableName unexpected response: ${response.statusCode}');
        print(
          'Response: ${responseBody.length > 200 ? responseBody.substring(0, 200) + "..." : responseBody}',
        );
    }
  } catch (e) {
    print('❌ Failed to test $tableName table: $e');
  }
}

Future<void> testSignupEndpoint(
  HttpClient client,
  String supabaseUrl,
  String supabaseAnonKey,
) async {
  try {
    final request = await client.postUrl(
      Uri.parse('$supabaseUrl/auth/v1/signup'),
    );
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('apikey', supabaseAnonKey);
    request.headers.set('Content-Type', 'application/json');

    // Test with invalid data to see if endpoint responds
    request.write(
      json.encode({
        'email': 'test@example.com',
        'password': 'short', // Too short, should fail
      }),
    );

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    switch (response.statusCode) {
      case 400:
        if (responseBody.contains('password')) {
          print('✅ Signup endpoint working (400 = validation error expected)');
        } else {
          print('⚠️ Signup endpoint returned 400: $responseBody');
        }
        break;
      case 422:
        print('✅ Signup endpoint working (422 = validation error expected)');
        break;
      case 404:
        print('❌ Signup endpoint not found');
        break;
      case 500:
        print('❌ Signup endpoint has server error - DATABASE ISSUE LIKELY');
        print('Response: $responseBody');
        break;
      default:
        print('⚠️ Signup endpoint response: ${response.statusCode}');
        print(
          'Response: ${responseBody.length > 200 ? responseBody.substring(0, 200) + "..." : responseBody}',
        );
    }
  } catch (e) {
    print('❌ Failed to test signup endpoint: $e');
  }
}
