// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'receipts_page.dart';
import 'add_trips_page.dart';
import 'profile_page.dart';
import 'trips_view.dart';
import 'true_home_page.dart';

const Color darkBackgroundColor = Color(0xFF204051);
const Color textPrimaryColor = Colors.white;
const Color primaryActionColor = Color(0xFF4AB19D);
const Color bottomNavIconColor = Colors.white;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;

  static const List<Widget> _pages = <Widget>[
    TrueHomePage(),
    TripsView(),
    SizedBox.shrink(),
    ReceiptsPage(),
    ProfilePage(),
  ];

  static const List<String> _appBarTitles = <String>[
    'Home',
    'Your Trips',
    '',
    'Receipts',
    'Profile'
  ];

  void _onBottomNavItemTapped(int index) {
    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTripsPage()));
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // --- MODIFIED: Simplified to be more robust ---
  Future<void> _joinTrip(String shareCode) async {
    if (shareCode.isEmpty) return;
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('shareCode', isEqualTo: shareCode.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trip not found. Please check the code.")));
        return;
      }

      final tripDoc = querySnapshot.docs.first;
      await FirebaseFirestore.instance.collection('trips').doc(tripDoc.id).update({
        'members': FieldValue.arrayUnion([user.uid])
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Successfully joined '${tripDoc['title']}'!")));

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("An error occurred. Please try again.")));
      print("Error joining trip: $e");
    }
  }

  Future<void> _showJoinTripDialog() async {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: darkBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: const Text('Join a Trip', style: TextStyle(color: textPrimaryColor)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: codeController,
              autofocus: true,
              style: const TextStyle(color: textPrimaryColor),
              decoration: const InputDecoration(
                  hintText: "Enter Share Code",
                  hintStyle: TextStyle(color: Color(0xFFB0B0B0))
              ),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a code.' : null,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFB0B0B0))),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryActionColor),
              child: const Text('Join', style: TextStyle(color: Colors.white)),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final code = codeController.text;
                  Navigator.of(dialogContext).pop();
                  _joinTrip(code);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF2A4A5A),
        elevation: 0,
        title: Text(
          _appBarTitles[_selectedIndex],
          style: const TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          if (_selectedIndex == 1)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.group_add_outlined, color: primaryActionColor, size: 30),
                  onPressed: _showJoinTripDialog,
                  tooltip: 'Join Trip',
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: primaryActionColor, size: 30),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTripsPage())),
                  tooltip: 'Add Trip',
                ),
              ],
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF2A4A5A),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(icon: Icon(Icons.home, color: _selectedIndex == 0 ? primaryActionColor : bottomNavIconColor), onPressed: () => _onBottomNavItemTapped(0)),
            IconButton(icon: Icon(Icons.card_travel, color: _selectedIndex == 1 ? primaryActionColor : bottomNavIconColor), onPressed: () => _onBottomNavItemTapped(1)),
            const SizedBox(width: 40),
            IconButton(icon: Icon(Icons.receipt_long, color: _selectedIndex == 3 ? primaryActionColor : bottomNavIconColor), onPressed: () => _onBottomNavItemTapped(3)),
            IconButton(icon: Icon(Icons.person, color: _selectedIndex == 4 ? primaryActionColor : bottomNavIconColor), onPressed: () => _onBottomNavItemTapped(4)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onBottomNavItemTapped(2),
        backgroundColor: primaryActionColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}