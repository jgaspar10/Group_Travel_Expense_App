// lib/pages/trip_overview_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';
import '../models/expense_model.dart';
import 'add_trips_page.dart';

// Your existing color constants from other files
const Color darkBackgroundColor = Color(0xFF204051);
const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color primaryActionColor = Color(0xFF4AB19D);
const Color inputFieldFillColor = Color(0xFF2A4A5A);
const Color actionButtonColor = Color(0xFF5856D6);

class TripOverviewPage extends StatefulWidget {
  final Trip trip;

  const TripOverviewPage({super.key, required this.trip});

  @override
  State<TripOverviewPage> createState() => _TripOverviewPageState();
}

class _TripOverviewPageState extends State<TripOverviewPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, String> _memberNames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {})); // Rebuild on tab change to update FAB
    _fetchMemberNames();
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMemberNames() async {
    if (widget.trip.members.isEmpty) return;
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: widget.trip.members).get();
      final Map<String, String> fetchedNames = {};
      for (var doc in usersSnapshot.docs) {
        fetchedNames[doc.id] = doc.data()['name'] ?? 'Unknown User';
      }
      if (mounted) {
        setState(() {
          _memberNames = fetchedNames;
        });
      }
    } catch (e) {
      print("Error fetching member names: $e");
    }
  }

  void _showAddExpenseDialog() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedPayerId = FirebaseAuth.instance.currentUser?.uid;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: darkBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: const Text('Add New Expense', style: TextStyle(color: textPrimaryColor)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: descriptionController,
                  style: const TextStyle(color: textPrimaryColor),
                  decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: textSecondaryColor)),
                  validator: (val) => val!.isEmpty ? 'Enter a description' : null,
                ),
                TextFormField(
                  controller: amountController,
                  style: const TextStyle(color: textPrimaryColor),
                  decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$', labelStyle: TextStyle(color: textSecondaryColor)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) => val!.isEmpty ? 'Enter an amount' : null,
                ),
                StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return DropdownButtonFormField<String>(
                        value: selectedPayerId,
                        dropdownColor: darkBackgroundColor,
                        style: const TextStyle(color: textPrimaryColor),
                        decoration: const InputDecoration(labelText: 'Paid by', labelStyle: TextStyle(color: textSecondaryColor)),
                        items: _memberNames.entries.map((entry) {
                          return DropdownMenuItem(value: entry.key, child: Text(entry.value));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPayerId = value;
                          });
                        },
                        validator: (val) => val == null ? 'Select who paid' : null,
                      );
                    }
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: textSecondaryColor))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryActionColor),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _saveExpense(
                    description: descriptionController.text.trim(),
                    amount: double.tryParse(amountController.text) ?? 0.0,
                    payerId: selectedPayerId!,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveExpense({required String description, required double amount, required String payerId}) async {
    final newExpense = Expense(
      id: '',
      description: description,
      amount: amount,
      paidBy: payerId,
      createdAt: Timestamp.now(),
    );

    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.trip.id)
          .collection('expenses')
          .add(newExpense.toMap());
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add expense: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 220.0,
              pinned: true,
              backgroundColor: darkBackgroundColor,
              iconTheme: const IconThemeData(color: textPrimaryColor),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AddTripsPage(tripToEdit: widget.trip)));
                  },
                  style: TextButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Edit', style: TextStyle(color: textPrimaryColor)),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, right: 20, bottom: 55),
                centerTitle: false,
                title: Text(widget.trip.title, style: const TextStyle(color: textPrimaryColor, fontSize: 22.0, fontWeight: FontWeight.bold)),
                background: Hero(
                  tag: 'trip_image_${widget.trip.id}',
                  child: Image.network(widget.trip.imageUrl, fit: BoxFit.cover, color: Colors.black.withOpacity(0.4), colorBlendMode: BlendMode.darken),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: textPrimaryColor,
                unselectedLabelColor: textSecondaryColor,
                indicatorColor: primaryActionColor,
                tabs: const [Tab(text: "Overview"), Tab(text: "Plans"), Tab(text: "Expenses")],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildPlansList(),
            _buildExpensesList(),
          ],
        ),
      ),
      floatingActionButton: _tabController.index != 0
          ? FloatingActionButton(
        onPressed: _tabController.index == 1 ? _showAddPlanDialog : _showAddExpenseDialog,
        backgroundColor: actionButtonColor,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  Widget _buildExpensesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.trip.id)
          .collection('expenses')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: textPrimaryColor)));
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No expenses added yet.', style: TextStyle(color: textSecondaryColor)));
        }

        final expenses = snapshot.data!.docs.map((doc) => Expense.fromFirestore(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final payerName = _memberNames[expense.paidBy] ?? '...';

            return Card(
              color: inputFieldFillColor,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: const Icon(Icons.receipt, color: textSecondaryColor),
                title: Text(expense.description, style: const TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold)),
                subtitle: Text('Paid by $payerName on ${DateFormat.yMd().format(expense.createdAt.toDate())}', style: const TextStyle(color: textSecondaryColor)),
                trailing: Text('\$${expense.amount.toStringAsFixed(2)}', style: const TextStyle(color: primaryActionColor, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlansList() {
    // This is a placeholder for now
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit_calendar, size: 60, color: textSecondaryColor),
          const SizedBox(height: 16),
          const Text('No plans added yet.', style: TextStyle(color: textSecondaryColor)),
        ],
      ),
    );
  }

  void _showAddPlanDialog() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Plan dialog (TODO)')));
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(color: inputFieldFillColor, borderRadius: BorderRadius.circular(12.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Expenses', style: TextStyle(color: textPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Spent: \$0 of \$0', style: TextStyle(color: textSecondaryColor)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: 0.0, backgroundColor: textSecondaryColor.withOpacity(0.3), valueColor: const AlwaysStoppedAnimation<Color>(primaryActionColor), minHeight: 8),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _showAddExpenseDialog,
          icon: const Icon(Icons.add, color: textPrimaryColor),
          label: const Text('Add Expense', style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: actionButtonColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
        ),
        const SizedBox(height: 24),
        const Text('Action Items', style: TextStyle(color: textPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: Colors.blue),
          title: Text('Balance calculations coming soon!', style: TextStyle(color: textPrimaryColor)),
          trailing: Text('Settle Up', style: TextStyle(color: primaryActionColor)),
        ),
      ],
    );
  }
}
