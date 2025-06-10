// lib/pages/home_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_trips_page.dart';
import '../models/trip_model.dart';

// Color Constants
const Color darkBackgroundColor = Color(0xFF204051);
const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color circularButtonBackgroundColor = Colors.white;
const Color circularButtonIconColor = darkBackgroundColor;
const Color dialogOptionColor = textPrimaryColor;
const Color dialogIconColor = textPrimaryColor;
const Color textSecondaryColor_50 = Colors.white54;
const Color amountBadgeColor = Color(0xFF6A5ACD);

class HomePage extends StatefulWidget {
  final String? displayName;
  final String? userCode;

  const HomePage({super.key, this.displayName, this.userCode});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  Future<void> _showAddOptionsDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: darkBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: const Text('New Group Options', style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.group_add_outlined, color: dialogIconColor),
                title: const Text('Create new group', style: TextStyle(color: dialogOptionColor)),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTripsPage()));
                },
              ),


              const Divider(color: textSecondaryColor_50),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner, color: dialogIconColor),
                title: const Text('Join a group with code', style: TextStyle(color: dialogOptionColor)),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Join a group selected (TODO)')),
                  );
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: textSecondaryColor)),
              onPressed: () => Navigator.of(dialogContext).pop(),
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
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Trips', style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('trips').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}', style: const TextStyle(color: textPrimaryColor)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.luggage_outlined, size: 80, color: textSecondaryColor.withAlpha(128)),
                  const SizedBox(height: 20),
                  const Text('No trips yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimaryColor)),
                  const SizedBox(height: 10),
                  const Text("Tap the '+' button to add your first trip.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: textSecondaryColor)),
                ],
              ),
            );
          }

          final List<Trip> trips = snapshot.data!.docs.map((doc) {
            return Trip.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return GestureDetector(
                onTap: () {
                  // Navigate to AddTripsPage and pass the trip to be edited
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTripsPage(tripToEdit: trip),
                    ),
                  );
                },
                child: TripCard(trip: trip),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptionsDialog(context),
        backgroundColor: circularButtonBackgroundColor,
        foregroundColor: circularButtonIconColor,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}

// --- TripCard Widget ---
class TripCard extends StatelessWidget {
  final Trip trip;
  const TripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 220,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: trip.imageUrl.startsWith('http')
                  ? Image.network(
                trip.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[800], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50))),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null, strokeWidth: 2, color: textPrimaryColor));
                },
              )
                  : Image.file(
                File(trip.imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[800], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50))),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withAlpha(153), Colors.transparent, Colors.black.withAlpha(153)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(trip.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimaryColor, shadows: [Shadow(blurRadius: 2, color: Colors.black54)])),
                  const SizedBox(height: 4),
                  Text(trip.location, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: textPrimaryColor, shadows: [Shadow(blurRadius: 1, color: Colors.black54)])),
                  const SizedBox(height: 4),
                  Text(trip.date, style: const TextStyle(fontSize: 12, color: textSecondaryColor, shadows: [Shadow(blurRadius: 1, color: Colors.black54)])),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: amountBadgeColor, borderRadius: BorderRadius.circular(20)),
                child: Text(trip.amount, style: const TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}