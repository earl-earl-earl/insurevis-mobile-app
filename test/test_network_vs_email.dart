import 'dart:convert';
import 'dart:io';

/// Test to verify network connectivity vs email configuration issue
void main() async {
  print('🌐 Testing Network Connectivity vs Email Configuration...\n');

  const String supabaseUrl = 'https://vvnsludqdidnqpbzzgeb.supabase.co';
  const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2bnNsdWRxZGlkbnFwYnp6Z2ViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNDg3MjIsImV4cCI6MjA3MDcyNDcyMn0.aFtPK2qhVJw3z324PjuM-q7e5_4J55mgm7A2fqkLO3c';

  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 10);

  try {
    print('1️⃣ Testing basic connectivity to Supabase...');
    await testBasicConnectivity(client, supabaseUrl, supabaseAnonKey);

    print('\n2️⃣ Testing database operations (should work)...');
    await testDatabaseRead(client, supabaseUrl, supabaseAnonKey);

    print('\n3️⃣ Testing auth signin (should work)...');
    await testSignin(client, supabaseUrl, supabaseAnonKey);

    print('\n4️⃣ Testing auth signup (fails due to email, not network)...');
    await testSignupEmailIssue(client, supabaseUrl, supabaseAnonKey);
  } catch (e) {
    print('❌ Network error: $e');
  } finally {
    client.close();
  }

  print('\n🎯 **Conclusion:**');
  print('If steps 1-3 work but step 4 fails with email error,');
  print('then network is fine - it\'s purely an email configuration issue.');
}

Future<void> testBasicConnectivity(
  HttpClient client,
  String supabaseUrl,
  String supabaseAnonKey,
) async {
  try {
    final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/'));
    request.headers.set('apikey', supabaseAnonKey);

    final response = await request.close();
    print('✅ Basic connectivity: ${response.statusCode} (server reachable)');
  } catch (e) {
    print('❌ Basic connectivity failed: $e');
  }
}

Future<void> testDatabaseRead(
  HttpClient client,
  String supabaseUrl,
  String supabaseAnonKey,
) async {
  try {
    final request = await client.getUrl(
      Uri.parse('$supabaseUrl/rest/v1/users?select=count&limit=1'),
    );
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('apikey', supabaseAnonKey);

    final response = await request.close();
    print('✅ Database read: ${response.statusCode} (database accessible)');
  } catch (e) {
    print('❌ Database read failed: $e');
  }
}

Future<void> testSignin(
  HttpClient client,
  String supabaseUrl,
  String supabaseAnonKey,
) async {
  try {
    final request = await client.postUrl(
      Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password'),
    );
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('apikey', supabaseAnonKey);
    request.headers.set('Content-Type', 'application/json');

    // Test with invalid credentials (should return 400, not network error)
    request.write(
      json.encode({'email': 'fake@example.com', 'password': 'wrongpassword'}),
    );

    final response = await request.close();
    print(
      '✅ Auth signin endpoint: ${response.statusCode} (auth server working)',
    );
  } catch (e) {
    print('❌ Auth signin failed: $e');
  }
}

Future<void> testSignupEmailIssue(
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

    final testEmail =
        'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    request.write(
      json.encode({
        'email': testEmail,
        'password': 'TestPassword123!',
        'data': {'name': 'Test User'},
      }),
    );

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    print('Auth signup status: ${response.statusCode}');

    if (response.statusCode == 500 &&
        responseBody.contains('confirmation email')) {
      print('🎯 CONFIRMED: Email configuration issue, NOT network issue');
      print('   The server is reachable, auth works, but email service fails');
    } else if (response.statusCode == 200) {
      print('✅ Signup worked! Email might be fixed now');
    } else {
      print('Response: $responseBody');
    }
  } catch (e) {
    print('❌ Signup test failed: $e');
  }
}
