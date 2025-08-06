// lib/pages/registration_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color darkBackgroundColor = Color(0xFF204051);
const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color accentColor = Colors.white;
const Color inputLineColor = Colors.white38;
const Color inputFocusedLineColor = Colors.white;
const Color circularButtonBackgroundColor = Colors.white;
const Color circularButtonIconColor = darkBackgroundColor;

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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) { return; }

    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'uid': userCredential.user!.uid,
          'currency': 'GBP',
        });

        // The AuthGate will handle navigation automatically.
        if (mounted) Navigator.pop(context); // Just close the loading dialog
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'An unknown error occurred.')));
    }
  }

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
                padding: EdgeInsets.fromLTRB(screenWidth * 0.05, screenHeight * 0.05, screenWidth * 0.08, screenHeight * 0.02),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: screenHeight * 0.03),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Name',
                        validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty || !v.contains('@') ? 'Please enter a valid email' : null,
                      ),
                      SizedBox(height: screenHeight * 0.03),
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
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            decoration: BoxDecoration(color: circularButtonBackgroundColor, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 10, offset: const Offset(0, 5))]),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Sign Up', style: TextStyle(color: circularButtonIconColor, fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: circularButtonIconColor, size: 20)
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Have we met before? ", style: TextStyle(color: textSecondaryColor, fontSize: screenHeight * 0.018)),
                          TextButton(
                            onPressed: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: Text('Sign in', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: screenHeight * 0.018)),
                          ),
                        ],
                      ),
                    ],
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