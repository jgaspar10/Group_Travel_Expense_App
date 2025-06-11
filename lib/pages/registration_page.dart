// lib/pages/registration_page.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'home_page.dart';

// Dark Theme Colors
const Color darkBackgroundColor = Color(0xFF204051);
const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color accentColor = Colors.white;
const Color inputLineColor = Colors.white38;
const Color inputFocusedLineColor = Colors.white;
const Color circularButtonBackgroundColor = Colors.white;
const Color circularButtonIconColor = darkBackgroundColor;
const Color secondaryActionColor = Color(0xFF4AB19D); // A teal for "Start Anonymously"

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

  void _register() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement actual registration logic with Firebase Auth
      print('Registering user...');
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  void _startAnonymously() {
    _showNameInputDialog(context);
  }

  Future<void> _showNameInputDialog(BuildContext pageContext) async {
    final nameController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: pageContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: darkBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: const Text('Enter Your Name', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimaryColor)),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: nameController,
              style: const TextStyle(color: textPrimaryColor),
              decoration: const InputDecoration(
                  hintText: "E.g., Alex",
                  hintStyle: TextStyle(color: textSecondaryColor),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: inputLineColor)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: inputFocusedLineColor))),
              validator: (v) => v!.trim().isEmpty ? 'Please enter a name' : null,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: textSecondaryColor)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: circularButtonBackgroundColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              child: const Text('Continue', style: TextStyle(color: circularButtonIconColor)),
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  final name = nameController.text.trim();
                  Navigator.of(dialogContext).pop();
                  _showGeneratedCode(pageContext, name);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showGeneratedCode(BuildContext pageContext, String name) async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final randomCode = String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    final userCode = '${name.replaceAll(' ', '').substring(0, min(name.replaceAll(' ', '').length, 4)).toUpperCase()}-$randomCode';

    return showDialog<void>(
      context: pageContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: darkBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: Text('Hi $name!', style: const TextStyle(fontWeight: FontWeight.bold, color: textPrimaryColor)),
          content: Text('Here is your unique login code. Please save it securely:\n\n$userCode', style: const TextStyle(color: textPrimaryColor)),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: circularButtonBackgroundColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              child: const Text('Okay, Continue', style: TextStyle(color: circularButtonIconColor)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.pushNamedAndRemoveUntil(pageContext, '/home', (route) => false, arguments: {'displayName': name, 'userCode': userCode});
              },
            ),
          ],
        );
      },
    );
  }

  // Helper for text fields
  Widget _buildTextField({required TextEditingController controller, required String label, bool obscureText = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: textPrimaryColor),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: textSecondaryColor), enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: inputLineColor)), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: inputFocusedLineColor))),
      obscureText: obscureText,
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
                          const Spacer(flex: 2), // Pushes content down
                          _buildTextField(
                            controller: _nameController,
                            label: 'Name',
                            validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
                          ),
                          SizedBox(height: screenHeight * 0.025),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
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
                          const Row(
                            children: <Widget>[
                              Expanded(child: Divider(color: inputLineColor)),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 12.0), child: Text('OR', style: TextStyle(color: textSecondaryColor))),
                              Expanded(child: Divider(color: inputLineColor)),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          OutlinedButton(
                            onPressed: _startAnonymously,
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: secondaryActionColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                padding: const EdgeInsets.symmetric(vertical: 14)
                            ),
                            child: const Text('Start Anonymously', style: TextStyle(color: secondaryActionColor, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Have we met before? ", style: TextStyle(color: textSecondaryColor, fontSize: screenHeight * 0.018)),
                              TextButton(
                                onPressed: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                },
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                                child: Text('Sign in', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: screenHeight * 0.018)),
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