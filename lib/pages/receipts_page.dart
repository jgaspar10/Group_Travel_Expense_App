// lib/pages/receipts_page.dart
import 'package:flutter/material.dart';

const Color textSecondaryColor = Colors.white70;

class ReceiptsPage extends StatelessWidget {
  const ReceiptsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'All Receipts\n(Coming Soon)',
        textAlign: TextAlign.center,
        style: TextStyle(color: textSecondaryColor, fontSize: 18),
      ),
    );
  }
}