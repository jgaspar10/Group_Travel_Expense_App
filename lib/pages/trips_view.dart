// lib/pages/trips_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'trip_overview_page.dart';
import '../models/trip_model.dart';

const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color primaryActionColor = Color(0xFF4AB19D);

class TripsView extends StatefulWidget {
  const TripsView({super.key});

  @override
  State<TripsView> createState() => _TripsViewState();
}

class _TripsViewState extends State<TripsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Column(
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
    );
  }

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
    // --- THIS SECTION IS NOW CORRECTED ---
    final String startDate = DateFormat('d MMM y').format(trip.startDate.toDate());
    final String endDate = DateFormat('d MMM y').format(trip.endDate.toDate());

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
              Positioned(
                bottom: 20,
                left: 20,
                // --- THIS LINE IS THE FIX ---
                child: Text('$startDate - $endDate', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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