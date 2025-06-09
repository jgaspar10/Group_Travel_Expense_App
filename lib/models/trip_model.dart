// lib/models/trip_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String title;
  final String location;
  final String date;
  final String imageUrl;
  // final int rating; // REMOVED
  final String amount;

  Trip({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.imageUrl,
    // required this.rating, // REMOVED
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': date,
      'imageUrl': imageUrl,
      // 'rating': rating, // REMOVED
      'amount': amount,
      'createdAt': Timestamp.now(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] ?? '',
      title: map['title'] ?? 'No Title',
      location: map['location'] ?? 'No Location',
      date: map['date'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      // rating: map['rating'] ?? 0, // REMOVED
      amount: map['amount'] ?? '0\$',
    );
  }
}