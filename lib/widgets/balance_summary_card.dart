// lib/widgets/balance_summary_card.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

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
  bool _isLoading = true;
  double _totalTripCost = 0.0;
  Map<String, double> _balances = {};

  @override
  void initState() {
    super.initState();
    _calculateBalances();
  }

  Future<void> _calculateBalances() async {
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
    _totalTripCost = totalCost;

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
    _balances = finalBalances;

    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
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
          Text('Total Spent: \$${_totalTripCost.toStringAsFixed(2)}', style: const TextStyle(color: textSecondaryColor)),
          const Divider(color: textSecondaryColor, height: 24),
          // Build a list of balances for each member
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
                    balance >= 0
                        ? 'is owed \$${balance.toStringAsFixed(2)}'
                        : 'owes \$${(-balance).toStringAsFixed(2)}',
                    style: TextStyle(
                        color: balance >= 0 ? Colors.greenAccent : Colors.redAccent,
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