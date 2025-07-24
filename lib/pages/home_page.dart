// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_trips_page.dart';
import 'trip_overview_page.dart';
import 'profile_page.dart'; // Keep this import
import '../models/trip_model.dart';

// Your color constants...
const Color darkBackgroundColor = Color(0xFF204051);
const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color primaryActionColor = Color(0xFF4AB19D);
const Color bottomNavIconColor = Colors.white;
const Color bottomNavSelectedIconColor = Color(0xFF4AB19D);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 1;

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
    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTripsPage()));
    } else if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
    } else {
      setState(() { _bottomNavIndex = index; });
      // TODO: Handle navigation to other main pages (Home, Receipts)
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Your Trips', style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 28)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: primaryActionColor, size: 30),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTripsPage())),
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
              tabs: const [Tab(text: "Active"), Tab(text: "Upcoming"), Tab(text: "Past")],
            ),
            Expanded(
              // --- REVERTED to original TabBarView structure ---
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTripsList(user),
                  const Center(child: Text('Upcoming trips will be shown here.', style: TextStyle(color: textSecondaryColor))),
                  const Center(child: Text('Past trips will be shown here.', style: TextStyle(color: textSecondaryColor))),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: darkBackgroundColor.withBlue(60),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(icon: Icon(Icons.home, color: _bottomNavIndex == 0 ? primaryActionColor : bottomNavIconColor), onPressed: () => _onBottomNavItemTapped(0)),
            IconButton(icon: Icon(Icons.card_travel, color: _bottomNavIndex == 1 ? primaryActionColor : bottomNavIconColor), onPressed: () => _onBottomNavItemTapped(1)),
            const SizedBox(width: 40),
            IconButton(icon: Icon(Icons.receipt_long, color: _bottomNavIndex == 3 ? primaryActionColor : bottomNavIconColor), onPressed: () => _onBottomNavItemTapped(3)),
            IconButton(icon: Icon(Icons.person, color: _bottomNavIndex == 4 ? primaryActionColor : bottomNavIconColor), onPressed: () => _onBottomNavItemTapped(4)),
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

  // --- REVERTED to the original _buildTripsList function ---
  Widget _buildTripsList(User? user) {
    if (user == null) {
      return const Center(child: Text("Please log in to see your trips.", style: TextStyle(color: textSecondaryColor, fontSize: 18)));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').where('members', arrayContains: user.uid).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong!', style: TextStyle(color: Colors.redAccent)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryActionColor));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("You have no active trips.\nTap '+' to create one!", textAlign: TextAlign.center, style: TextStyle(color: textSecondaryColor, fontSize: 18))));
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

class NewTripCard extends StatelessWidget {
  final Trip trip;
  const NewTripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TripOverviewPage(trip: trip)),
        );
      },
      child: Container(
        height: 150,
        margin: const EdgeInsets.only(bottom: 20.0),
        child: Hero(
          tag: 'trip_image_${trip.id}',
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Image.network(trip.imageUrl, fit: BoxFit.cover),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    gradient: LinearGradient(colors: [Colors.black.withOpacity(0.6), Colors.transparent], begin: Alignment.centerLeft, end: Alignment.centerRight, stops: const [0.0, 0.8]),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(children: [const Icon(Icons.location_on, color: Colors.white, size: 16), const SizedBox(width: 4), Text(trip.location, style: const TextStyle(color: Colors.white, fontSize: 14))]),
                  ],
                ),
              ),
              // --- REVERTED to using the original trip.date field ---
              Positioned(
                bottom: 20,
                left: 20,
                child: Text(trip.date, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: Row(children: [const Icon(Icons.group, color: Colors.white, size: 16), const SizedBox(width: 4), Text(trip.members.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 14))]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}