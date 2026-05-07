import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final companyController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  void navigateToLogin() {
    Navigator.pop(context); // Go back to login
  }

  Future<void> register() async {
    setState(() => _isLoading = true);
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final name = nameController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      setState(() => _isLoading = false);
      return;
    }

    final AuthService _authService = AuthService();
    try {
      final response = await _authService.signUpWithEmail(email, password);
      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registration failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Side: Registration Form
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  if (MediaQuery.of(context).size.width > 800)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: -5,
                    ),
                ],
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48.0,
                    vertical: 48.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children:
                          [
                                // Header
                                Center(
                                  child:
                                      Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.blueAccent
                                                      .withOpacity(0.3),
                                                  blurRadius: 20,
                                                  spreadRadius: 5,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.person_add_alt_1_rounded,
                                              size: 72,
                                              color: Colors.blueAccent,
                                            ),
                                          )
                                          .animate(
                                            onPlay: (controller) => controller
                                                .repeat(reverse: true),
                                          )
                                          .scale(
                                            begin: const Offset(1, 1),
                                            end: const Offset(1.05, 1.05),
                                            duration: 1200.ms,
                                            curve: Curves.easeInOut,
                                          )
                                          .shimmer(
                                            duration: 2400.ms,
                                            color: Colors.white,
                                          ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Create Account',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.blueAccent,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Join MedRep 360 today and streamline your workflow.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 48),

                                // Name Field
                                TextField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Company Name Field
                                TextField(
                                  controller: companyController,
                                  decoration: InputDecoration(
                                    labelText: 'Company Name',
                                    prefixIcon: const Icon(
                                      Icons.business_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Email Field
                                TextField(
                                  controller: emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 20),

                                // Password Field
                                TextField(
                                  controller: passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Confirm Password Field
                                TextField(
                                  controller: confirmPasswordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                ),
                                const SizedBox(height: 48),

                                // Register Button
                                if (_isLoading)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else
                                  Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blueAccent
                                                  .withOpacity(0.4),
                                              blurRadius: 16,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: register,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 18,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            backgroundColor: Colors.blueAccent,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                          ),
                                          child: const Text(
                                            'Register',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                      .animate(
                                        onPlay: (controller) =>
                                            controller.repeat(),
                                      )
                                      .shimmer(
                                        duration: 2000.ms,
                                        color: Colors.white24,
                                        angle: 0.5,
                                      ),
                                const SizedBox(height: 32),

                                // Login Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account?',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 16,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: navigateToLogin,
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blueAccent,
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      child: const Text('Login Here'),
                                    ),
                                  ],
                                ),
                              ]
                              .animate(interval: 50.ms)
                              .fade(duration: 800.ms)
                              .slideY(begin: 0.2, curve: Curves.easeOutQuart),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Right Side: Medical Image (hidden on small screens)
          if (MediaQuery.of(context).size.width > 800)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1551076805-e18690c5e53b?q=80&w=2000&auto=format&fit=crop',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withOpacity(0.8),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomRight,
                      end: Alignment.topLeft,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Advanced\nData Analytics',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ).animate().fade(duration: 800.ms).slideX(begin: 0.2),
                        const SizedBox(height: 16),
                        const Text(
                              'Gain insights into your medical\nnetwork and interactions instantly.',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            )
                            .animate()
                            .fade(duration: 800.ms, delay: 200.ms)
                            .slideX(begin: 0.2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
