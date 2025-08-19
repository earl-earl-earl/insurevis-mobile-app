import 'dart:convert';
import 'dart:io';

/// Test the fixed signup process
void main() async {
  print('🧪 Testing FIXED signup process...\n');

  const String supabaseUrl = 'https://vvnsludqdidnqpbzzgeb.supabase.co';
  const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2bnNsdWRxZGlkbnFwYnp6Z2ViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNDg3MjIsImV4cCI6MjA3MDcyNDcyMn0.aFtPK2qhVJw3z324PjuM-q7e5_4J55mgm7A2fqkLO3c';

  final client = HttpClient();

  try {
    final testEmail =
        'final_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    print('📧 Testing with: $testEmail');
    print('🔧 Using fixed signup logic (no manual database inserts)\n');

    // Test the complete fixed flow
    print('1️⃣ Creating auth account (triggers will handle database)...');
    final authResult = await createAuthAccount(
      client,
      supabaseUrl,
      supabaseAnonKey,
      testEmail,
    );

    if (authResult['success'] == true) {
      print('✅ Auth account created successfully!');
      final userId = authResult['user_id'];
      final accessToken = authResult['access_token'];

      // Wait a moment for triggers to complete
      await Future.delayed(Duration(seconds: 2));

      print('\n2️⃣ Checking if database triggers created user profile...');
      final profileExists = await checkUserProfile(
        client,
        supabaseUrl,
        supabaseAnonKey,
        userId,
        accessToken,
      );

      if (profileExists) {
        print('✅ User profile created automatically by triggers!');
        print('\n🎉 COMPLETE SUCCESS!');
        print('   ✅ Auth account created');
        print('   ✅ Database triggers handled profile creation');
        print('   ✅ No duplicate key errors');
        print('   ✅ Your app should now work perfectly!');
      } else {
        print('⚠️ User profile not found - triggers might not be working');
      }
    } else {
      print('❌ Auth signup failed: ${authResult['error']}');
    }
  } catch (e) {
    print('❌ Test error: $e');
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> createAuthAccount(
  HttpClient client,
  String supabaseUrl,
  String supabaseAnonKey,
  String email,
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
        'password': 'TestPassword123!',
        'data': {'name': 'Test User', 'email': email},
      }),
    );

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      return {
        'success': true,
        'user_id': data['user']['id'],
        'access_token': data['access_token'],
      };
    } else {
      return {'success': false, 'error': responseBody};
    }
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

Future<bool> checkUserProfile(
  HttpClient client,
  String supabaseUrl,
  String supabaseAnonKey,
  String userId,
  String accessToken,
) async {
  try {
    final request = await client.getUrl(
      Uri.parse('$supabaseUrl/rest/v1/users?id=eq.$userId'),
    );
    request.headers.set('Authorization', 'Bearer $accessToken');
    request.headers.set('apikey', supabaseAnonKey);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      return data is List && data.isNotEmpty;
    }
    return false;
  } catch (e) {
    return false;
  }
}
