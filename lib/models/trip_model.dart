// lib/models/trip_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String title;
  final String location;
  final String date;
  final String imageUrl;
  final String amount;
  final List<String> members; // Stores UIDs of confirmed members
  final List<String> invitedEmails; // ADDED: Stores emails of invited users
  final String shareCode;

  Trip({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.amount,
    required this.members,
    required this.invitedEmails, // ADDED
    required this.shareCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': date,
      'imageUrl': imageUrl,
      'amount': amount,
      'members': members,
      'invitedEmails': invitedEmails, // ADDED
      'shareCode': shareCode,
      'createdAt': Timestamp.now(),
    };
  }

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      location: data['location'] ?? 'No Location',
      date: data['date'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      amount: data['amount'] ?? '0\$',
      // Read the list of member UIDs from the database
      members: List<String>.from(data['members'] ?? []),
      invitedEmails: List<String>.from(data['invitedEmails'] ?? []), // ADDED
      shareCode: data['shareCode'] ?? '',
    );
  }
}
