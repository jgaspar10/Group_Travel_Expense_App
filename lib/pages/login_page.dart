// lib/pages/login_page.dart
import 'package:flutter/material.dart';

// Dark Theme Colors
const Color darkBackgroundColor = Color(0xFF204051);
const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color accentColor = Colors.white;
const Color inputLineColor = Colors.white38;
const Color inputFocusedLineColor = Colors.white;
const Color circularButtonBackgroundColor = Colors.white;
const Color circularButtonIconColor = darkBackgroundColor;
const Color secondaryActionColor = Color(0xFF4AB19D); // A teal for outlined buttons/links

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement actual login logic with Firebase Auth
      print('Name/Email: ${_nameOrEmailController.text}');
      print('Password: ${_passwordController.text}');

      // On successful login, navigate to home and remove auth screens from stack
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
                child: RotatedBox(
                  quarterTurns: -1,
                  child: Text('sign in', textAlign: TextAlign.center, style: TextStyle(color: textPrimaryColor, fontSize: screenHeight * 0.07, fontWeight: FontWeight.w900, letterSpacing: 6)),
                ),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch, // Makes children like buttons stretch
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Spacer(flex: 2), // Pushes content down
                          TextFormField(
                            controller: _nameOrEmailController,
                            style: const TextStyle(color: textPrimaryColor),
                            decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: textSecondaryColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: inputLineColor)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: inputFocusedLineColor))),
                            validator: (v) => v!.isEmpty ? 'Please enter your name or email' : null,
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
                          SizedBox(height: screenHeight * 0.04), // Space between button and link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center, // Centered the link
                            children: [
                              Text("Your first time? ", style: TextStyle(color: textSecondaryColor, fontSize: screenHeight * 0.018)),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/register'),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                                child: Text('Sign up', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: screenHeight * 0.018)),
                              ),
                            ],
                          ),
                          const Spacer(flex: 3), // Pushes content up from bottom
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