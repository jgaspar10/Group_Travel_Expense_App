// lib/pages/true_home_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';

// Color constants for styling
const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color primaryActionColor = Color(0xFF4AB19D);
const Color inputFieldFillColor = Color(0xFF2A4A5A);

class TrueHomePage extends StatelessWidget {
  const TrueHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    // This query finds the user's next single upcoming trip
    final Stream<QuerySnapshot> stream = FirebaseFirestore.instance
        .collection('trips')
        .where('members', arrayContains: user?.uid)
        .where('startDate', isGreaterThan: Timestamp.now())
        .orderBy('startDate', descending: false)
        .limit(1)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryActionColor));
        }
        // Handle error state
        if (snapshot.hasError) {
          print("Error fetching countdown trip: ${snapshot.error}");
          return const Center(child: Text('Could not load trip data.', style: TextStyle(color: textSecondaryColor)));
        }
        // Handle no upcoming trips
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'You have no upcoming trips.\nPlan one now!',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondaryColor, fontSize: 18),
            ),
          );
        }

        // If we have data, build the countdown card
        final tripDoc = snapshot.data!.docs.first;
        final trip = Trip.fromFirestore(tripDoc);
        final daysUntil = trip.startDate.toDate().difference(DateTime.now()).inDays;

        String countdownText;
        if (daysUntil < 0) { // Should not happen with the query, but good to handle
          countdownText = 'is past';
        } else if (daysUntil == 0) {
          countdownText = 'is Today!';
        } else if (daysUntil == 1) {
          countdownText = 'is Tomorrow!';
        } else {
          countdownText = 'in $daysUntil days';
        }

        return Center(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: inputFieldFillColor,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trip.title,
                  style: const TextStyle(
                    color: textPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  countdownText,
                  style: const TextStyle(
                    color: primaryActionColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}