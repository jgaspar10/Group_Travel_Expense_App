// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';
  bool _isLoading = true;

  String? _selectedCurrency;
  final Map<String, String> _currencies = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (currentUser != null) {
      try {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        if (userDoc.exists) {
          if (mounted) {
            setState(() {
              _userName = userDoc.get('name');
              _userEmail = userDoc.get('email');
              _selectedCurrency = userDoc.get('currency') ?? 'GBP'; // CHANGED: Fallback currency is now GBP
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        print("Error fetching user data: $e");
        if (mounted) {
          setState(() {
            _userName = "Error";
            _userEmail = "Could not fetch data";
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _updateCurrency(String? newCurrency) async {
    if (newCurrency == null || currentUser == null) return;

    setState(() {
      _selectedCurrency = newCurrency;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'currency': newCurrency});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Currency updated!')),
        );
      }
    } catch (e) {
      print("Error updating currency: $e");
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: primaryActionColor))
        : Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: primaryActionColor,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              _userName,
              style: const TextStyle(
                color: textPrimaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _userEmail,
              style: const TextStyle(
                color: textSecondaryColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}