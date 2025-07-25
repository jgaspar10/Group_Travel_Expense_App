// lib/models/expense_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String description;
  final double amount;
  final String paidBy; // This will store the UID of the user who paid
  final Timestamp createdAt;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.createdAt,
  });

  // Method to convert an Expense object into a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'createdAt': createdAt,
    };
  }

  // Factory constructor to create an Expense object from a Firestore document
  factory Expense.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      description: data['description'] ?? 'No Description',
      amount: (data['amount'] ?? 0.0).toDouble(),
      paidBy: data['paidBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
