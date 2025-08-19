import 'dart:convert';
import 'dart:io';

/// Test to check if accounts are actually being created despite email errors
void main() async {
  print('🧪 Testing if accounts are created despite email errors...\n');

  const String supabaseUrl = 'https://vvnsludqdidnqpbzzgeb.supabase.co';
  const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2bnNsdWRxZGlkbnFwYnp6Z2ViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNDg3MjIsImV4cCI6MjA3MDcyNDcyMn0.aFtPK2qhVJw3z324PjuM-q7e5_4J55mgm7A2fqkLO3c';

  final client = HttpClient();

  try {
    final testEmail =
        'account_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    final testPassword = 'TestPassword123!';

    print('📧 Testing with: $testEmail');
    print('🔑 Password: $testPassword\n');

    // Step 1: Try to sign up (will fail with email error)
    print('1️⃣ Attempting signup (expected to fail with email error)...');
    final signupResult = await attemptSignup(
      client,
      supabaseUrl,
      supabaseAnonKey,
      testEmail,
      testPassword,
    );

    if (signupResult['success'] == true) {
      print('✅ Signup successful!');
      return;
    } else {
      print('❌ Signup failed as expected: ${signupResult['error']}');
    }

    // Step 2: Wait a moment, then try to sign in
    print(
      '\n2️⃣ Waiting 3 seconds, then testing if account was created anyway...',
    );
    await Future.delayed(Duration(seconds: 3));

    final signinResult = await attemptSignin(
      client,
      supabaseUrl,
      supabaseAnonKey,
      testEmail,
      testPassword,
    );

    if (signinResult['success'] == true) {
      print('🎉 ACCOUNT WAS CREATED! You can sign in despite the email error.');
      print(
        '   This means the auth account exists, but email verification failed.',
      );
      print(
        '   Users should try signing in even after getting the error message.',
      );
    } else {
      print('❌ Account was not created: ${signinResult['error']}');
      print('   The signup process completely failed.');
    }
  } catch (e) {
    print('❌ Test error: $e');
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> attemptSignup(
  HttpClient client,
  String supabaseUrl,
  String supabaseAnonKey,
  String email,
  String password,
) async {
  try {
    final request = await client.postUrl(
      Uri.parse('$supabaseUrl/auth/v1/signup'),
    );
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('apikey', supabaseAnonKey);
    request.headers.set('Content-Type', 'application/json');

    request.write(
      json.encode({
        'email': email,
        'password': password,
        'data': {'name': 'Test User'},
      }),
    );

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      return {'success': true, 'data': json.decode(responseBody)};
    } else {
      return {'success': false, 'error': responseBody};
    }
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

Future<Map<String, dynamic>> attemptSignin(
  HttpClient client,
  String supabaseUrl,
  String supabaseAnonKey,
  String email,
  String password,
) async {
  try {
    final request = await client.postUrl(
      Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password'),
    );
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('apikey', supabaseAnonKey);
    request.headers.set('Content-Type', 'application/json');

    request.write(json.encode({'email': email, 'password': password}));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      return {'success': true, 'data': json.decode(responseBody)};
    } else {
      return {'success': false, 'error': responseBody};
    }
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
