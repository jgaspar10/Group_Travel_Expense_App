// lib/services/user_data_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDataService with ChangeNotifier {
  // Singleton pattern to ensure only one instance of the service
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  StreamSubscription? _userSubscription;

  String? userName;
  String? userEmail;
  String? currencyCode; // e.g., 'GBP'
  String? currencySymbol; // e.g., '£'

  final Map<String, String> _currencies = {
    'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥',
  };

  // Starts listening to the user's document in Firestore
  void listenToUserData(String uid) {
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        userName = data['name'];
        userEmail = data['email'];
        currencyCode = data['currency'] ?? 'GBP';
        currencySymbol = _currencies[currencyCode];

        // Notify any listening widgets that the data has changed
        notifyListeners();
      }
    });
  }

  // Stops the listener when the user logs out
  void dispose() {
    _userSubscription?.cancel();
    userName = null;
    userEmail = null;
    currencyCode = null;
    currencySymbol = null;
  }
}