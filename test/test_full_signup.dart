import 'dart:convert';
import 'dart:io';

/// Test script to simulate the exact signup process and identify where it fails
void main() async {
  print('🔍 Testing Full Signup Process...\n');

  const String supabaseUrl = 'https://vvnsludqdidnqpbzzgeb.supabase.co';
  const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2bnNsdWRxZGlkbnFwYnp6Z2ViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNDg3MjIsImV4cCI6MjA3MDcyNDcyMn0.aFtPK2qhVJw3z324PjuM-q7e5_4J55mgm7A2fqkLO3c';

  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 30);

  try {
    // Generate unique test email
    final testEmail =
        'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    print('📧 Using test email: $testEmail');

    print('\n1️⃣ Step 1: Testing actual signup...');
    final authResult = await testActualSignup(
      client,
      supabaseUrl,
      supabaseAnonKey,
      testEmail,
    );

    if (authResult['success'] == true) {
      print('✅ Auth signup successful');

      final userId = authResult['user_id'];
      final accessToken = authResult['access_token'];

      if (userId != null && accessToken != null) {
        print('\n2️⃣ Step 2: Testing manual user table insert...');
        await testUserTableInsert(
          client,
          supabaseUrl,
          supabaseAnonKey,
          userId,
          testEmail,
          accessToken,
        );

        print('\n3️⃣ Step 3: Testing user_stats table insert...');
        await testUserStatsInsert(
          client,
          supabaseUrl,
          supabaseAnonKey,
          userId,
          accessToken,
        );
      }
    } else {
      print('❌ Auth signup failed: ${authResult['error']}');
      await analyzeSignupError(authResult['error'].toString());
    }
  } catch (e) {
    print('❌ Error during test: $e');
  } finally {
    client.close();
  }

  print('\n💡 **Next Steps:**');
  print('1. If auth works but table inserts fail → RLS policy issue');
  print('2. If auth fails with "server error" → Database trigger issue');
  print('3. If email already exists → Normal validation');
  print('4. Check Supabase dashboard logs for detailed errors');
}

Future<Map<String, dynamic>> testActualSignup(
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

    final signupData = {
      'email': email,
      'password': 'TestPassword123!',
      'data': {'name': 'Test User', 'phone': '+1234567890', 'email': email},
    };

    request.write(json.encode(signupData));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    print('Auth response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      return {
        'success': true,
        'user_id': data['user']?['id'],
        'access_token': data['access_token'],
        'response': data,
      };
    } else {
      return {
        'success': false,
        'error': responseBody,
        'status': response.statusCode,
      };
    }
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}

Future<void> testUserTableInsert(
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
      'is_email_verified': false,
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

    print('Users table insert status: ${response.statusCode}');

    if (response.statusCode == 201) {
      print('✅ Users table insert successful');
    } else {
      print('❌ Users table insert failed: $responseBody');
    }
  } catch (e) {
    print('❌ Users table insert error: $e');
  }
}

Future<void> testUserStatsInsert(
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

    print('User_stats table insert status: ${response.statusCode}');

    if (response.statusCode == 201) {
      print('✅ User_stats table insert successful');
    } else {
      print('❌ User_stats table insert failed: $responseBody');
    }
  } catch (e) {
    print('❌ User_stats table insert error: $e');
  }
}

Future<void> analyzeSignupError(String error) async {
  print('\n🔍 Analyzing error: $error');

  if (error.contains('trigger')) {
    print('🎯 **TRIGGER ISSUE:** Database trigger is likely failing');
    print('   → Check if handle_new_user() function exists');
    print('   → Check if trigger on_auth_user_created is working');
  } else if (error.contains('permission') || error.contains('policy')) {
    print('🎯 **RLS POLICY ISSUE:** Row Level Security blocking operation');
    print('   → Check RLS policies on users and user_stats tables');
  } else if (error.contains('already exists') || error.contains('unique')) {
    print('🎯 **DUPLICATE DATA:** Email or user already exists');
  } else if (error.contains('timeout')) {
    print('🎯 **TIMEOUT ISSUE:** Operation taking too long');
  } else if (error.contains('server') || error.contains('500')) {
    print('🎯 **SERVER ERROR:** Likely database configuration issue');
  } else {
    print('🎯 **UNKNOWN ERROR:** Check Supabase dashboard logs');
  }
}
