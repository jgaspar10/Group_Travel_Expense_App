// lib/pages/home_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_trips_page.dart';
import '../models/trip_model.dart'; // Ensure this path is correct

// Your existing color constants...
const Color darkBackgroundColor = Color(0xFF204051);
const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color primaryActionColor = Color(0xFF4AB19D); // Using this as the selected/accent color

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 1; // Default to 'Trips' tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onBottomNavItemTapped(int index) {
    if (index == 2) { // The center '+' button
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTripsPage()));
    } else {
      setState(() {
        _bottomNavIndex = index;
      });
      // TODO: Handle navigation to other main pages (Home, Expenses, Profile)
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes back button
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Your Trips', style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 28)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: primaryActionColor, size: 30),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTripsPage()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: textPrimaryColor,
              unselectedLabelColor: textSecondaryColor,
              indicatorColor: primaryActionColor,
              indicatorWeight: 3.0,
              tabs: const [
                Tab(text: "Active"),
                Tab(text: "Upcoming"),
                Tab(text: "Past"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Each tab will build a list. For now, they all show the same list.
                  _buildTripsList(user), // Active Trips
                  _buildTripsList(user), // Upcoming Trips (placeholder)
                  _buildTripsList(user), // Past Trips (placeholder)
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: darkBackgroundColor.withBlue(60), // A slightly different shade for the bar
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(icon: Icon(Icons.home, color: _bottomNavIndex == 0 ? primaryActionColor : textSecondaryColor), onPressed: () => _onBottomNavItemTapped(0)),
            IconButton(icon: Icon(Icons.card_travel, color: _bottomNavIndex == 1 ? primaryActionColor : textSecondaryColor), onPressed: () => _onBottomNavItemTapped(1)),
            const SizedBox(width: 40), // Placeholder for the FAB notch
            IconButton(icon: Icon(Icons.receipt_long, color: _bottomNavIndex == 3 ? primaryActionColor : textSecondaryColor), onPressed: () => _onBottomNavItemTapped(3)),
            IconButton(icon: Icon(Icons.person, color: _bottomNavIndex == 4 ? primaryActionColor : textSecondaryColor), onPressed: () => _onBottomNavItemTapped(4)),
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

  Widget _buildTripsList(User? user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .where('members', arrayContains: user?.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong', style: const TextStyle(color: textSecondaryColor)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "You have no trips in this category.\nTap '+' to create one!",
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondaryColor, fontSize: 18),
              ),
            ),
          );
        }

        final List<Trip> trips = snapshot.data!.docs.map((doc) => Trip.fromFirestore(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.only(top: 20.0),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            return NewTripCard(trip: trips[index]);
          },
        );
      },
    );
  }
}

// --- NEW Redesigned Trip Card Widget ---
class NewTripCard extends StatelessWidget {
  final Trip trip;
  const NewTripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to the new Trip Overview page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tapped on ${trip.title}')),
        );
      },
      child: Container(
        height: 150,
        margin: const EdgeInsets.only(bottom: 20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          image: DecorationImage(
            image: NetworkImage(trip.imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3), // Dark overlay for text contrast
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                trip.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        trip.location,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.group, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        trip.members.length.toString(),
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Date: ${trip.date}",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
