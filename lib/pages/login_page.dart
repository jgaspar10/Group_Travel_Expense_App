// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Your color constants...
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
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  void _loadUserEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? email = prefs.getString('rememberedEmail');
    if (email != null) {
      setState(() {
        _emailController.text = email;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('rememberedEmail', _emailController.text.trim());
    } else {
      await prefs.remove('rememberedEmail');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // The AuthGate will handle navigation automatically.
      // We no longer need to navigate manually from here.
      if (mounted) Navigator.pop(context); // Just close the loading dialog

    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context);
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMessage = 'No user found for that email or wrong password.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
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
              child: Align(alignment: Alignment.topCenter, child: RotatedBox(quarterTurns: -1, child: Text('sign in', textAlign: TextAlign.center, style: TextStyle(color: textPrimaryColor, fontSize: screenHeight * 0.07, fontWeight: FontWeight.w900, letterSpacing: 6)))),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(screenWidth * 0.05, screenHeight * 0.05, screenWidth * 0.08, screenHeight * 0.02),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: screenHeight * 0.1),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: textPrimaryColor),
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: textSecondaryColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: inputLineColor)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: inputFocusedLineColor))),
                        validator: (v) => v!.isEmpty ? 'Please enter your email' : null,
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: textPrimaryColor),
                        decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: textSecondaryColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: inputLineColor)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: inputFocusedLineColor))),
                        obscureText: true,
                        validator: (v) => v!.isEmpty ? 'Please enter your password' : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: accentColor,
                                checkColor: darkBackgroundColor,
                                side: const BorderSide(color: textSecondaryColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text("Remember me", style: TextStyle(color: textSecondaryColor)),
                          ],
                        ),
                      ),
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
                            decoration: BoxDecoration(color: circularButtonBackgroundColor, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 10, offset: const Offset(0, 5))]),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Sign In', style: TextStyle(color: circularButtonIconColor, fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(width: 8), Icon(Icons.arrow_forward, color: circularButtonIconColor, size: 20)]),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Your first time? ", style: TextStyle(color: textSecondaryColor, fontSize: screenHeight * 0.018)),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/register'),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: Text('Sign up', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: screenHeight * 0.018)),
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