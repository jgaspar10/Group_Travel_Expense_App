// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_data_service.dart';

const Color darkBackgroundColor = Color(0xFF204051);
const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color primaryActionColor = Color(0xFF4AB19D);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserDataService _userDataService = UserDataService();
  final Map<String, String> _currencies = { 'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥' };

  @override
  void initState() {
    super.initState();
    _userDataService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _userDataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _updateCurrency(String? newCurrency) async {
    if (newCurrency == null || FirebaseAuth.instance.currentUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'currency': newCurrency});
    } catch (e) {
      print("Error updating currency: $e");
    }
  }

  Future<void> _signOut() async {
    _userDataService.dispose();
    await FirebaseAuth.instance.signOut();
    // No navigation needed here. The AuthGate will handle it.
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 50, backgroundColor: primaryActionColor, child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 20),
            Text(
              _userDataService.userName ?? 'Loading...',
              style: const TextStyle(color: textPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _userDataService.userEmail ?? 'Loading...',
              style: const TextStyle(color: textSecondaryColor, fontSize: 16),
            ),
            const SizedBox(height: 40),
            DropdownButtonFormField<String>(
              value: _userDataService.currencyCode,
              items: _currencies.keys.map((String key) {
                return DropdownMenuItem<String>(
                  value: key,
                  child: Text('$key (${_currencies[key]})'),
                );
              }).toList(),
              onChanged: _updateCurrency,
              decoration: InputDecoration(
                labelText: 'Default Currency',
                labelStyle: const TextStyle(color: textSecondaryColor),
                filled: true,
                fillColor: const Color(0xFF2A4A5A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
              dropdownColor: const Color(0xFF2A4A5A),
              style: const TextStyle(color: textPrimaryColor),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}