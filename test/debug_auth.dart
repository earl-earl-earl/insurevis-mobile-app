import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/config/supabase_config.dart';
import '../lib/services/supabase_service.dart';

/// Debug sign-in screen to test authentication
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const DebugAuthApp());
}

class DebugAuthApp extends StatelessWidget {
  const DebugAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Auth Debug',
      home: const DebugSignInScreen(),
    );
  }
}

class DebugSignInScreen extends StatefulWidget {
  const DebugSignInScreen({super.key});

  @override
  State<DebugSignInScreen> createState() => _DebugSignInScreenState();
}

class _DebugSignInScreenState extends State<DebugSignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String _result = '';
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _testSignIn() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing sign-in...';
    });

    try {
      final result = await SupabaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        _result = 'Sign-in result:\n${result.toString()}';
      });
    } catch (e) {
      setState(() {
        _result = 'Sign-in error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSignUp() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing sign-up...';
    });

    try {
      final result = await SupabaseService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        _result = 'Sign-up result:\n${result.toString()}';
      });
    } catch (e) {
      setState(() {
        _result = 'Sign-up error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing connection...';
    });

    try {
      final isConnected = await SupabaseService.checkConnection();
      final testResults = await SupabaseService.testConfiguration();

      setState(() {
        _result =
            'Connection test:\n'
            'Connected: $isConnected\n\n'
            'Configuration test:\n'
            '${testResults.toString()}';
      });
    } catch (e) {
      setState(() {
        _result = 'Connection test error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Auth Debug'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text('Mode: '),
                Switch(
                  value: _isSignUp,
                  onChanged: (value) {
                    setState(() {
                      _isSignUp = value;
                    });
                  },
                ),
                Text(_isSignUp ? 'Sign Up' : 'Sign In'),
              ],
            ),
            const SizedBox(height: 16),

            if (_isSignUp) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : (_isSignUp ? _testSignUp : _testSignIn),
                    child: Text(_isSignUp ? 'Test Sign Up' : 'Test Sign In'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testConnection,
                    child: const Text('Test Connection'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _result.isEmpty ? 'Results will appear here...' : _result,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
