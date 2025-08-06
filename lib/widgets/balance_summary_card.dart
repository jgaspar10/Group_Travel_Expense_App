// lib/widgets/balance_summary_card.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import '../services/user_data_service.dart'; // Import the service

// Color constants
const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color inputFieldFillColor = Color(0xFF2A4A5A);
const Color primaryActionColor = Color(0xFF4AB19D);

class BalanceSummaryCard extends StatefulWidget {
  final String tripId;
  final List<String> memberUids;
  final Map<String, String> memberNames;

  const BalanceSummaryCard({
    super.key,
    required this.tripId,
    required this.memberUids,
    required this.memberNames,
  });

  @override
  State<BalanceSummaryCard> createState() => _BalanceSummaryCardState();
}

class _BalanceSummaryCardState extends State<BalanceSummaryCard> {
  final UserDataService _userDataService = UserDataService();
  bool _isLoading = true;
  double _totalTripCost = 0.0;
  Map<String, double> _balances = {};

  @override
  void initState() {
    super.initState();
    _calculateBalances();
  }

  // This method is now automatically called when the parent widget rebuilds
  // due to a currency change, so we don't need a separate listener here.
  @override
  void didUpdateWidget(covariant BalanceSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate if the members change (e.g., someone new joins)
    if (widget.memberUids.length != oldWidget.memberUids.length) {
      _calculateBalances();
    }
  }

  Future<void> _calculateBalances() async {
    setState(() { _isLoading = true; });

    if (widget.memberUids.isEmpty) {
      setState(() { _isLoading = false; });
      return;
    }

    // 1. Fetch all expenses for the trip
    final expensesSnapshot = await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .collection('expenses')
        .get();

    final expenses = expensesSnapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();

    // 2. Calculate total cost
    double totalCost = 0;
    for (var expense in expenses) {
      totalCost += expense.amount;
    }

    // 3. Calculate each person's share
    final double sharePerPerson = totalCost / widget.memberUids.length;

    // 4. Calculate how much each person paid
    Map<String, double> totalPaidPerMember = { for (var uid in widget.memberUids) uid : 0.0 };
    for (var expense in expenses) {
      totalPaidPerMember[expense.paidBy] = (totalPaidPerMember[expense.paidBy] ?? 0) + expense.amount;
    }

    // 5. Calculate final balances
    Map<String, double> finalBalances = {};
    for (var uid in widget.memberUids) {
      final paid = totalPaidPerMember[uid] ?? 0.0;
      finalBalances[uid] = paid - sharePerPerson;
    }

    if(mounted) {
      setState(() {
        _totalTripCost = totalCost;
        _balances = finalBalances;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = _userDataService.currencySymbol ?? '£';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: inputFieldFillColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryActionColor))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Balances', style: TextStyle(color: textPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Total Spent: $currencySymbol${_totalTripCost.toStringAsFixed(2)}', style: const TextStyle(color: textSecondaryColor)),
          const Divider(color: textSecondaryColor, height: 24),

          ...widget.memberUids.map((uid) {
            final balance = _balances[uid] ?? 0.0;
            final name = widget.memberNames[uid] ?? 'Unknown User';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: const TextStyle(color: textPrimaryColor, fontSize: 16)),
                  Text(
                    balance.abs() < 0.01 // Use a small tolerance for zero
                        ? 'is settled up'
                        : balance > 0
                        ? 'is owed $currencySymbol${balance.toStringAsFixed(2)}'
                        : 'owes $currencySymbol${(-balance).toStringAsFixed(2)}',
                    style: TextStyle(
                        color: balance.abs() < 0.01 ? textSecondaryColor : (balance > 0 ? Colors.greenAccent : Colors.redAccent),
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}