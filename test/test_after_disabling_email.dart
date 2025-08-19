import 'dart:convert';
import 'dart:io';

/// Test signup after disabling email confirmation in Supabase
void main() async {
  print('🧪 Testing signup after disabling email confirmation...\n');

  const String supabaseUrl = 'https://vvnsludqdidnqpbzzgeb.supabase.co';
  const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2bnNsdWRxZGlkbnFwYnp6Z2ViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNDg3MjIsImV4cCI6MjA3MDcyNDcyMn0.aFtPK2qhVJw3z324PjuM-q7e5_4J55mgm7A2fqkLO3c';

  final client = HttpClient();

  try {
    final testEmail =
        'fixed_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    print('📧 Testing with: $testEmail');
    print(
      '📝 Make sure you\'ve disabled email confirmation in Supabase dashboard first!\n',
    );

    final request = await client.postUrl(
      Uri.parse('$supabaseUrl/auth/v1/signup'),
    );
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('apikey', supabaseAnonKey);
    request.headers.set('Content-Type', 'application/json');

    request.write(
      json.encode({
        'email': testEmail,
        'password': 'TestPassword123!',
        'data': {'name': 'Test User', 'email': testEmail},
      }),
    );

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    print('📋 Signup Response:');
    print('Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      print('🎉 SUCCESS! Account created successfully!');
      final data = json.decode(responseBody);
      print('User ID: ${data['user']?['id']}');
      print('Email: ${data['user']?['email']}');
      print('✅ Email confirmation is now disabled and signup works!');
    } else {
      print('❌ Still failing: $responseBody');
      print('\n💡 Make sure to:');
      print('1. Go to Supabase Dashboard → Authentication → Settings');
      print('2. Uncheck "Enable email confirmations"');
      print('3. Save the settings');
      print('4. Try this test again');
    }
  } catch (e) {
    print('❌ Test error: $e');
  } finally {
    client.close();
  }
}
