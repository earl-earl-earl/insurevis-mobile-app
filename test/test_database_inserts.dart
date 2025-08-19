import 'dart:convert';
import 'dart:io';

/// Test to check if database inserts are failing after auth signup
void main() async {
  print('🔍 Testing database inserts after successful auth signup...\n');

  const String supabaseUrl = 'https://vvnsludqdidnqpbzzgeb.supabase.co';
  const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2bnNsdWRxZGlkbnFwYnp6Z2ViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNDg3MjIsImV4cCI6MjA3MDcyNDcyMn0.aFtPK2qhVJw3z324PjuM-q7e5_4J55mgm7A2fqkLO3c';

  final client = HttpClient();

  try {
    final testEmail =
        'db_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    print('📧 Testing with: $testEmail\n');

    // Step 1: Create auth account
    print('1️⃣ Creating auth account...');
    final authResult = await createAuthAccount(
      client,
      supabaseUrl,
      supabaseAnonKey,
      testEmail,
    );

    if (authResult['success'] != true) {
      print('❌ Auth signup failed: ${authResult['error']}');
      return;
    }

    print('✅ Auth account created successfully!');
    final userId = authResult['user_id'];
    final accessToken = authResult['access_token'];

    // Step 2: Test users table insert
    print('\n2️⃣ Testing users table insert...');
    final usersResult = await testUsersTableInsert(
      client,
      supabaseUrl,
      supabaseAnonKey,
      userId,
      testEmail,
      accessToken,
    );

    // Step 3: Test user_stats table insert
    print('\n3️⃣ Testing user_stats table insert...');
    final statsResult = await testUserStatsInsert(
      client,
      supabaseUrl,
      supabaseAnonKey,
      userId,
      accessToken,
    );

    // Analysis
    print('\n📊 Analysis:');
    if (usersResult['success'] && statsResult['success']) {
      print('✅ All database operations successful - app should work!');
    } else {
      print(
        '❌ Database operations failed - this is why your app shows errors!',
      );
      if (!usersResult['success']) {
        print('   • Users table insert failed: ${usersResult['error']}');
      }
      if (!statsResult['success']) {
        print('   • User_stats table insert failed: ${statsResult['error']}');
      }

      print('\n💡 Solutions:');
      print('1. Check RLS policies allow authenticated users to insert');
      print('2. Verify database triggers are working correctly');
      print('3. Consider temporarily disabling RLS for testing');
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

Future<Map<String, dynamic>> testUsersTableInsert(
  HttpClient client,
  String supabaseUrl,
  String supabaseAnonKey,
  String userId,
  String email,
  String accessToken,
) async {
  try {
    final request = await client.postUrl(
      Uri.parse('$supabaseUrl/rest/v1/users'),
    );
    request.headers.set('Authorization', 'Bearer $accessToken');
    request.headers.set('apikey', supabaseAnonKey);
    request.headers.set('Content-Type', 'application/json');

    final userData = {
      'id': userId,
      'name': 'Test User',
      'email': email,
      'phone': '+1234567890',
      'join_date': DateTime.now().toIso8601String(),
      'is_email_verified': true,
      'preferences': {
        'notifications': true,
        'darkMode': false,
        'language': 'en',
        'autoSync': true,
        'biometricLogin': false,
      },
    };

    request.write(json.encode(userData));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 201) {
      print('✅ Users table insert successful');
      return {'success': true};
    } else {
      print('❌ Users table insert failed: $responseBody');
      return {'success': false, 'error': responseBody};
    }
  } catch (e) {
    print('❌ Users table insert error: $e');
    return {'success': false, 'error': e.toString()};
  }
}

Future<Map<String, dynamic>> testUserStatsInsert(
  HttpClient client,
  String supabaseUrl,
  String supabaseAnonKey,
  String userId,
  String accessToken,
) async {
  try {
    final request = await client.postUrl(
      Uri.parse('$supabaseUrl/rest/v1/user_stats'),
    );
    request.headers.set('Authorization', 'Bearer $accessToken');
    request.headers.set('apikey', supabaseAnonKey);
    request.headers.set('Content-Type', 'application/json');

    final statsData = {
      'user_id': userId,
      'total_assessments': 0,
      'completed_assessments': 0,
      'documents_submitted': 0,
      'total_saved': 0.0,
      'last_active_date': DateTime.now().toIso8601String(),
    };

    request.write(json.encode(statsData));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 201) {
      print('✅ User_stats table insert successful');
      return {'success': true};
    } else {
      print('❌ User_stats table insert failed: $responseBody');
      return {'success': false, 'error': responseBody};
    }
  } catch (e) {
    print('❌ User_stats table insert error: $e');
    return {'success': false, 'error': e.toString()};
  }
}
