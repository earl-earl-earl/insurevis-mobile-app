import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/config/supabase_config.dart';
import '../lib/services/supabase_service.dart';

/// Simple test script to check Supabase connectivity
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🔍 Testing Supabase Configuration...\n');

  try {
    // Initialize Supabase
    print('📡 Initializing Supabase...');
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    print('✅ Supabase initialized successfully\n');

    // Test configuration
    print('🧪 Running configuration tests...');
    final testResults = await SupabaseService.testConfiguration();

    print('📊 Test Results:');
    testResults.forEach((key, value) {
      print('  $key: $value');
    });

    print('\n🔗 Testing connection...');
    final isConnected = await SupabaseService.checkConnection();
    print('Connection status: ${isConnected ? "✅ Connected" : "❌ Failed"}');

    if (!isConnected) {
      print('\n💡 Troubleshooting suggestions:');
      print('  1. Check if your Supabase project is active in the dashboard');
      print('  2. Verify the project URL and API key are correct');
      print('  3. Check your internet connection');
      print('  4. Make sure the project hasn\'t been paused due to billing');
    }
  } catch (e) {
    print('❌ Error during test: $e');

    if (e.toString().contains('404')) {
      print(
        '\n💡 This suggests your Supabase project URL is incorrect or the project is inactive.',
      );
      print(
        '   Please check your Supabase dashboard at https://supabase.com/dashboard',
      );
    } else if (e.toString().contains('401')) {
      print('\n💡 This suggests an authentication issue with your API key.');
      print('   Please verify your anon key in the Supabase dashboard.');
    }
  }
}
