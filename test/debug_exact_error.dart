import 'dart:convert';
import 'dart:io';

/// Test to see exactly what error message is being processed
void main() async {
  print('🔍 Testing exact error message processing...\n');

  const String supabaseUrl = 'https://vvnsludqdidnqpbzzgeb.supabase.co';
  const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2bnNsdWRxZGlkbnFwYnp6Z2ViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNDg3MjIsImV4cCI6MjA3MDcyNDcyMn0.aFtPK2qhVJw3z324PjuM-q7e5_4J55mgm7A2fqkLO3c';

  final client = HttpClient();

  try {
    final testEmail =
        'debug_${DateTime.now().millisecondsSinceEpoch}@example.com';
    print('📧 Testing with: $testEmail\n');

    final request = await client.postUrl(
      Uri.parse('$supabaseUrl/auth/v1/signup'),
    );
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('apikey', supabaseAnonKey);
    request.headers.set('Content-Type', 'application/json');

    final signupData = {
      'email': testEmail,
      'password': 'TestPassword123!',
      'data': {'name': 'Debug User', 'email': testEmail},
    };

    request.write(json.encode(signupData));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    print('📋 Raw Response:');
    print('Status: ${response.statusCode}');
    print('Body: $responseBody\n');

    if (response.statusCode != 200) {
      print('🔍 Error Analysis:');
      print('Raw error string: "$responseBody"');
      print('Lowercase: "${responseBody.toLowerCase()}"');

      final errorLower = responseBody.toLowerCase();

      print('\n🧪 Testing error conditions:');
      print(
        'Contains "error sending confirmation email": ${errorLower.contains('error sending confirmation email')}',
      );
      print(
        'Contains "confirmation email": ${errorLower.contains('confirmation email')}',
      );
      print(
        'Contains "email delivery failed": ${errorLower.contains('email delivery failed')}',
      );
      print('Contains "smtp": ${errorLower.contains('smtp')}');
      print(
        'Contains "unexpected_failure": ${errorLower.contains('unexpected_failure')}',
      );

      print('\n💡 This explains why your app shows "Failed to create account"');
      print(
        'The error mapping needs to be updated to catch this specific error format.',
      );
    }
  } catch (e) {
    print('❌ Test error: $e');
  } finally {
    client.close();
  }
}
