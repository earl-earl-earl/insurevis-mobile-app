import 'dart:convert';
import 'dart:io';

/// Simple connectivity test for Supabase without Flutter dependencies
void main() async {
  print('🔍 Testing Supabase Configuration...\n');

  const String supabaseUrl = 'https://vvnsludqdidnqpbzzgeb.supabase.co';
  const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2bnNsdWRxZGlkbnFwYnp6Z2ViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNDg3MjIsImV4cCI6MjA3MDcyNDcyMn0.aFtPK2qhVJw3z324PjuM-q7e5_4J55mgm7A2fqkLO3c';

  try {
    // Test 1: Basic URL accessibility
    print('📡 Testing basic URL connectivity...');
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    // Test the REST API endpoint
    final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/'));
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    request.headers.set('apikey', supabaseAnonKey);

    final response = await request.close();

    print('Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      print('✅ Supabase API is accessible and working');
    } else if (response.statusCode == 401) {
      print(
        '⚠️ Unauthorized - This is expected for API endpoint without specific resource',
      );
      print('   But it means the server is responding correctly');
    } else if (response.statusCode == 404) {
      print(
        '❌ 404 Not Found - Your Supabase project may be paused or URL is incorrect',
      );
    } else {
      print('⚠️ Unexpected status code: ${response.statusCode}');
    }

    // Read response body for more details
    final responseBody = await response.transform(utf8.decoder).join();
    print(
      'Response: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}',
    );

    client.close();
  } catch (e) {
    print('❌ Connection failed: $e');

    if (e.toString().contains('SocketException')) {
      print('\n💡 This suggests a network connectivity issue.');
      print('   - Check your internet connection');
      print('   - Verify the Supabase URL is correct');
      print('   - Check if there are any firewall restrictions');
    } else if (e.toString().contains('TimeoutException')) {
      print('\n💡 Connection timed out.');
      print('   - The server may be slow to respond');
      print('   - Try again in a few minutes');
    }
  }

  // Test 2: Check if the project URL format is correct
  print('\n🔍 Analyzing project configuration...');
  print('Project URL: $supabaseUrl');

  if (supabaseUrl.contains('.supabase.co')) {
    print('✅ URL format looks correct');
  } else {
    print('❌ URL format may be incorrect');
  }

  if (supabaseAnonKey.startsWith('eyJ')) {
    print('✅ Anon key format looks correct (JWT)');
  } else {
    print('❌ Anon key format may be incorrect');
  }

  print('\n📋 Next steps:');
  print('1. Check your Supabase dashboard at https://supabase.com/dashboard');
  print('2. Verify your project is active and not paused');
  print('3. Confirm the URL and anon key in your project settings');
  print('4. Check the "Settings > API" section for correct credentials');
}
