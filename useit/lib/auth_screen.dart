import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:useit/Pages/home.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool isLoginMode = true;
  bool isLoading = false;
  
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _nameController = TextEditingController();

  Future<void> _submitAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    User? authenticatedUser;
    String? errorMessage;
    var signupNeedsLogin = false;

    try {
      final auth = Supabase.instance.client.auth;
      final email = emailController.text.trim();
      final password = passwordController.text;

      if (isLoginMode) {
        final response = await auth.signInWithPassword(
          email: email,
          password: password,
        );
        authenticatedUser = response.user;
        if (authenticatedUser == null) {
          throw const AuthException('Sign-in did not return a user.');
        }
        await _saveProfile(authenticatedUser);
      } else {
        final fullName = _nameController.text.trim();
        final nameParts = fullName.split(RegExp(r'\s+'));
        final response = await auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'first_name': nameParts.first,
            'last_name': nameParts.skip(1).join(' '),
          },
        );
        authenticatedUser = response.user;
        if (authenticatedUser == null) {
          throw const AuthException('Sign-up did not return a user.');
        }
        await _saveProfile(authenticatedUser);
        signupNeedsLogin = response.session == null;
      }
    } on AuthException catch (error) {
      errorMessage = error.message;
    } catch (error) {
      errorMessage = 'Could not complete authentication: $error';
    } finally {
      if (mounted) setState(() => isLoading = false);
    }

    if (!mounted) return;
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
      return;
    }

    if (authenticatedUser == null) return;
    if (signupNeedsLogin) {
      setState(() => isLoginMode = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. You can now sign in.')),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(user: {
          'id': authenticatedUser!.id,
          'name': authenticatedUser.userMetadata?['full_name'] ??
              authenticatedUser.email?.split('@').first ??
              'User',
        }),
      ),
    );
  }

  Future<void> _saveProfile(User user) async {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fullName = (metadata['full_name'] ?? '').toString().trim();
    final nameParts = fullName.isEmpty ? <String>[] : fullName.split(RegExp(r'\s+'));

    await Supabase.instance.client.from('profiles').upsert({
      'id': user.id,
      'first_name': metadata['first_name'] ?? nameParts.firstOrNull,
      'last_name': metadata['last_name'] ??
          (nameParts.length > 1 ? nameParts.skip(1).join(' ') : null),
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLoginMode ? 'Sign In' : 'Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isLoginMode) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => !val!.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (val) => val!.length < 6 ? 'Password must be 6+ chars' : null,
                ),
                const SizedBox(height: 24),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                        onPressed: _submitAuth,
                        child: Text(isLoginMode ? 'Login' : 'Register'),
                      ),
                TextButton(
                  onPressed: () => setState(() => isLoginMode = !isLoginMode),
                  child: Text(isLoginMode ? "Don't have an account? Sign Up" : "Have an account? Log In"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}