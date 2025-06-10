// lib/pages/registration_page.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'home_page.dart';

// Your color constants...
const Color darkBackgroundColor = Color(0xFF204051);
const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color accentColor = Colors.white;
const Color inputLineColor = Colors.white38;
const Color inputFocusedLineColor = Colors.white;
const Color circularButtonBackgroundColor = Colors.white;
const Color circularButtonIconColor = darkBackgroundColor;
const Color secondaryActionColor = Color(0xFF4AB19D);

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- MODIFIED: _register method with Firebase Auth logic ---
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, do nothing.
    }

    // Show a loading indicator (optional but good UX)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Create user with email and password
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // If user creation is successful, save their details to Firestore
      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'uid': userCredential.user!.uid,
        });

        // Navigate to the HomePage and clear the previous routes
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      // This will handle errors like "email-already-in-use"
      if (mounted) {
        Navigator.pop(context); // Close the loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'An unknown error occurred.')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close the loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  void _startAnonymously() { /* ... same as before ... */ }
  Future<void> _showNameInputDialog(BuildContext pageContext) async { /* ... same as before ... */ }
  Future<void> _showGeneratedCode(BuildContext pageContext, String name) async { /* ... same as before ... */ }

  Widget _buildTextField({required TextEditingController controller, required String label, bool obscureText = false, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: textPrimaryColor),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: textSecondaryColor), enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: inputLineColor)), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: inputFocusedLineColor))),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
    );
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
                child: RotatedBox(quarterTurns: -1, child: Text('sign up', textAlign: TextAlign.center, style: TextStyle(color: textPrimaryColor, fontSize: screenHeight * 0.07, fontWeight: FontWeight.w900, letterSpacing: 6))),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(screenWidth * 0.05, screenHeight * 0.04, screenWidth * 0.08, screenHeight * 0.02),
                  child: Form(
                    key: _formKey,
                    child: SizedBox(
                      height: screenHeight * 0.9,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Spacer(flex: 2),
                          _buildTextField(
                            controller: _nameController,
                            label: 'Name',
                            validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
                          ),
                          SizedBox(height: screenHeight * 0.025),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please enter your email';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Please enter a valid email';
                              return null;
                            },
                          ),
                          SizedBox(height: screenHeight * 0.025),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            obscureText: true,
                            validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null,
                          ),
                          SizedBox(height: screenHeight * 0.05),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: _register,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(color: circularButtonBackgroundColor, shape: BoxShape.circle),
                                child: const Icon(Icons.arrow_forward, color: circularButtonIconColor),
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          const Row(children: <Widget>[Expanded(child: Divider(color: inputLineColor)), Padding(padding: EdgeInsets.symmetric(horizontal: 12.0), child: Text('OR', style: TextStyle(color: textSecondaryColor))), Expanded(child: Divider(color: inputLineColor))]),
                          SizedBox(height: screenHeight * 0.02),
                          OutlinedButton(
                            onPressed: _startAnonymously,
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: secondaryActionColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: const Text('Start Anonymously', style: TextStyle(color: secondaryActionColor, fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(flex: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Have we met before? ", style: TextStyle(color: textSecondaryColor, fontSize: screenHeight * 0.018)),
                              TextButton(
                                onPressed: () {
                                  if (Navigator.canPop(context)) { Navigator.pop(context); }
                                },
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                                child: Text('Sign in', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: screenHeight * 0.018)),
                              ),
                            ],
                          ),
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