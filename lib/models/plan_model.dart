// lib/models/plan_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Plan {
  final String id;
  final String title;
  final String description;
  final Timestamp time; // To store the specific date and time of the plan
  final Timestamp createdAt;

  Plan({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.createdAt,
  });

  // Method to convert a Plan object into a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'time': time,
      'createdAt': createdAt,
    };
  }

  // Factory constructor to create a Plan object from a Firestore document
  factory Plan.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Plan(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? 'No Description',
      time: data['time'] ?? Timestamp.now(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
