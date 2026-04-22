import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../controller/auth_controller.dart';
import 'user_info_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void handleSubmit() {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    if (isLogin) {
      ref.read(authControllerProvider).signInWithEmail(context, email, password);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserInfoScreen(email: email, password: password),
        ),
      );
    }
  }

  void handleForgotPassword() {
    String email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter your email first')));
      return;
    }
    ref.read(authControllerProvider).forgotPassword(context, email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Fi 💬',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: tabColor)),
              const SizedBox(height: 8),
              Text(isLogin ? 'Welcome back' : 'Create your account',
                  style: const TextStyle(fontSize: 16, color: greyColor)),
              const SizedBox(height: 40),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email, color: tabColor),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: tabColor)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: tabColor)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock, color: tabColor),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: tabColor)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: tabColor)),
                ),
              ),
              if (isLogin) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: handleForgotPassword,
                    child: const Text('Forgot Password?',
                        style: TextStyle(color: tabColor)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tabColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: handleSubmit,
                  child: Text(
                    isLogin ? 'LOGIN' : 'NEXT',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin
                      ? "Don't have an account? Sign Up"
                      : 'Already have an account? Login',
                  style: const TextStyle(color: tabColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}