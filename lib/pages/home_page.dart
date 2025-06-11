// lib/pages/home_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_trips_page.dart';
import '../models/trip_model.dart';

// Your color constants...
const Color darkBackgroundColor = Color(0xFF204051);
const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color circularButtonBackgroundColor = Colors.white;
const Color circularButtonIconColor = darkBackgroundColor;
const Color dialogOptionColor = textPrimaryColor;
const Color dialogIconColor = textPrimaryColor;
const Color textSecondaryColor_50 = Colors.white54;
const Color amountBadgeColor = Color(0xFF6A5ACD); // Color for amount badge
const Color deleteColor = Colors.redAccent;

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

  Future<void> _deleteTrip(String tripId) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(tripId).delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete trip: $e')));
      }
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: darkBackgroundColor,
          title: const Text('Delete Trip?', style: TextStyle(color: textPrimaryColor)),
          content: const Text('Are you sure you want to permanently delete this trip?', style: TextStyle(color: textSecondaryColor)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: textSecondaryColor)),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: deleteColor, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
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

          final List<Trip> trips = snapshot.data!.docs.map((doc) => Trip.fromFirestore(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return Dismissible(
                key: Key(trip.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: deleteColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete_forever, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  final bool? shouldDelete = await _showDeleteConfirmationDialog();
                  if (shouldDelete == true) {
                    await _deleteTrip(trip.id);
                  }
                  return shouldDelete;
                },
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddTripsPage(tripToEdit: trip)),
                    );
                  },
                  child: TripCard(trip: trip),
                ),
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

// --- THIS IS THE CORRECTED TripCard WIDGET ---
class TripCard extends StatelessWidget {
  final Trip trip;
  const TripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent, // Important for the Stack to be visible
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      clipBehavior: Clip.antiAlias, // Ensures the image is clipped to the rounded corners
      child: SizedBox(
        height: 220, // Define a fixed height for the card
        child: Stack(
          children: <Widget>[
            // 1. Background Image
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
            // 2. Gradient Overlay for text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withAlpha(180)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            // 3. Text Content and Badge
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(trip.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimaryColor, shadows: [Shadow(blurRadius: 2, color: Colors.black54)])),
                          const SizedBox(height: 4),
                          Text(trip.location, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: textPrimaryColor, shadows: [Shadow(blurRadius: 1, color: Colors.black54)])),
                          const SizedBox(height: 4),
                          Text(trip.date, style: const TextStyle(fontSize: 12, color: textSecondaryColor, shadows: [Shadow(blurRadius: 1, color: Colors.black54)])),
                        ],
                      ),
                    ),
                    // Right side amount badge
                    const SizedBox(width: 16), // Spacing
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: amountBadgeColor, borderRadius: BorderRadius.circular(20)),
                      child: Text(trip.amount, style: const TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}