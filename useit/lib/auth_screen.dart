import 'package:flutter/material.dart';
import 'package:useit/Pages/home.dart';
import 'package:useit/azure_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AzureService _azureService = AzureService();
  final _formKey = GlobalKey<FormState>();
  
  bool isLoginMode = true;
  bool isLoading = false;
  
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _nameController = TextEditingController();

  void _submitAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    Map<String, dynamic> result;

    if (isLoginMode) {
      result = await _azureService.login(
        emailController.text.trim(), 
        passwordController.text.trim(),
      );
    } else {
      result = await _azureService.register(
        emailController.text.trim(), 
        passwordController.text.trim(),
        _nameController.text.trim(),
      );
    }

    setState(() => isLoading = false);

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Success!'), backgroundColor: Colors.green),
      );
      if (isLoginMode) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen(user: result['user'])),
        );
      } else {
        setState(() => isLoginMode = true);
      }
    }
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
      appBar: AppBar(title: Text(isLoginMode ? 'Sign In to Azure' : 'Create Azure Account')),
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
