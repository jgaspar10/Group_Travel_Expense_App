// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

// Dark Theme Colors
const Color darkBackgroundColor = Color(0xFF204051);
const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color accentColor = Colors.white;
const Color inputLineColor = Colors.white38;
const Color inputFocusedLineColor = Colors.white;
const Color circularButtonBackgroundColor = Colors.white;
const Color circularButtonIconColor = darkBackgroundColor;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- MODIFIED: _login method with Firebase Auth logic ---
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do nothing
    }

    // Show a loading indicator for better user experience
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Sign in the user with their email and password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // If login is successful, navigate to the HomePage
      // and remove all previous routes (so the user can't go back to login)
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      // Close the loading indicator before showing the error
      if (mounted) Navigator.pop(context);

      // Handle specific Firebase authentication errors
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMessage = 'No user found for that email or wrong password.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided for that user.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: darkBackgroundColor,
      body: SafeArea(
        child: Row(
          children: <Widget>[
            Container(
              width: screenWidth * 0.25,
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: RotatedBox(quarterTurns: -1, child: Text('sign in', textAlign: TextAlign.center, style: TextStyle(color: textPrimaryColor, fontSize: screenHeight * 0.07, fontWeight: FontWeight.w900, letterSpacing: 6))),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(screenWidth * 0.05, screenHeight * 0.05, screenWidth * 0.08, screenHeight * 0.02),
                  child: Form(
                    key: _formKey,
                    child: SizedBox(
                      height: screenHeight * 0.9,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Spacer(flex: 2),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: textPrimaryColor),
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: textSecondaryColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: inputLineColor)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: inputFocusedLineColor))),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please enter your email';
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: textPrimaryColor),
                            decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: textSecondaryColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: inputLineColor)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: inputFocusedLineColor))),
                            obscureText: true,
                            validator: (v) => v!.isEmpty ? 'Please enter your password' : null,
                          ),
                          SizedBox(height: screenHeight * 0.015),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(onPressed: () {}, child: const Text('Forgot Password?', style: TextStyle(color: textSecondaryColor, fontSize: 13))),
                          ),
                          SizedBox(height: screenHeight * 0.05),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: _login,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                decoration: BoxDecoration(color: circularButtonBackgroundColor, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withAlpha((255 * 0.1).round()), blurRadius: 10, offset: const Offset(0, 5))]),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [Text('Ok', style: TextStyle(color: circularButtonIconColor, fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(width: 8), Icon(Icons.arrow_forward, color: circularButtonIconColor, size: 20)],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Your first time? ", style: TextStyle(color: textSecondaryColor, fontSize: screenHeight * 0.018)),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/register'),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                                child: Text('Sign up', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: screenHeight * 0.018)),
                              ),
                            ],
                          ),
                          const Spacer(flex: 3),
                        ],
                      ),
                    ),
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