import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _matricNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // NEW: Phone Controller
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _matricNoController.dispose();
    _emailController.dispose();
    _phoneController.dispose(); // NEW: Dispose it to prevent memory leaks
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      // Trigger the Riverpod Auth Controller's register method
      // Note: We are passing the phone number here now!
      await ref.read(authControllerProvider.notifier).register(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _nameController.text.trim(),
            _matricNoController.text.trim(),
            _phoneController.text.trim(), // NEW: Passing phone data
          );
      
      // If successful, navigate to the home dashboard
      if (ref.read(authControllerProvider).hasError == false && mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Join CampusFind',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const SizedBox(height: 32),

                  if (authState.hasError)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        authState.error.toString(),
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => value!.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _matricNoController,
                    decoration: const InputDecoration(
                      labelText: 'Matric Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (value) => value!.isEmpty ? 'Matric Number is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // NEW: Phone Number Input Field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone, // Opens number pad on mobile!
                    decoration: const InputDecoration(
                      labelText: 'Mobile Phone Number',
                      hintText: 'e.g., 0123456789',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_android),
                    ),
                    validator: (value) => value!.isEmpty ? 'Phone number is required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'University Email',
                      hintText: 'example@live.iium.edu.my',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email is required';
                      if (!value.endsWith('@live.iium.edu.my')) return 'Must use @live.iium.edu.my';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: authState.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                        : const Text('REGISTER NOW', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}