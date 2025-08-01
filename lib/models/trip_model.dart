// lib/models/trip_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String title;
  final String location;
  final Timestamp startDate;
  final Timestamp endDate;
  final String imageUrl;
  final List<String> members;
  final List<String> invitedEmails;
  final String shareCode;
  final double budget;
  final Timestamp createdAt;

  Trip({
    required this.id,
    required this.title,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.imageUrl,
    required this.members,
    required this.invitedEmails,
    required this.shareCode,
    required this.budget,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'startDate': startDate,
      'endDate': endDate,
      'imageUrl': imageUrl,
      'members': members,
      'invitedEmails': invitedEmails,
      'shareCode': shareCode,
      'budget': budget,
      'createdAt': createdAt,
    };
  }

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      location: data['location'] ?? 'No Location',
      startDate: data['startDate'] ?? Timestamp.now(),
      endDate: data['endDate'] ?? Timestamp.now(),
      imageUrl: data['imageUrl'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      invitedEmails: List<String>.from(data['invitedEmails'] ?? []),
      shareCode: data['shareCode'] ?? '',
      budget: (data['budget'] ?? 0.0).toDouble(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}