// lib/pages/true_home_page.dart
import 'package:flutter/material.dart';

const Color textSecondaryColor = Colors.white70;

class TrueHomePage extends StatelessWidget {
  const TrueHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Home Dashboard\n(Coming Soon)',
        textAlign: TextAlign.center,
        style: TextStyle(color: textSecondaryColor, fontSize: 18),
      ),
    );
  }
}