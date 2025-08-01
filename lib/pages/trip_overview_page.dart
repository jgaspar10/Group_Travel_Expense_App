// lib/pages/trip_overview_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';
import '../models/expense_model.dart';
import '../models/plan_model.dart';
import '../widgets/balance_summary_card.dart';
import 'add_trips_page.dart';

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
  // --- NEW: State variable to track if names are being loaded ---
  bool _isLoadingNames = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _fetchMemberNames();
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMemberNames() async {
    // Ensure the loading state is true at the start
    setState(() {
      _isLoadingNames = true;
    });

    if (widget.trip.members.isEmpty) {
      setState(() {
        _isLoadingNames = false;
      });
      return;
    }

    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: widget.trip.members).get();
      final Map<String, String> fetchedNames = {};
      for (var doc in usersSnapshot.docs) {
        fetchedNames[doc.id] = doc.data()['name'] ?? 'Unknown User';
      }
      if (mounted) {
        setState(() {
          _memberNames = fetchedNames;
          _isLoadingNames = false; // --- MODIFIED: Set loading to false after success ---
        });
      }
    } catch (e) {
      print("Error fetching member names: $e");
      if (mounted) {
        setState(() {
          _isLoadingNames = false; // --- MODIFIED: Also set loading to false on error ---
        });
      }
    }
  }

  // --- No changes to the dialogs or other functions, they will now work correctly ---
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

  void _showAddPlanDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: darkBackgroundColor,
                title: const Text('Add New Plan', style: TextStyle(color: textPrimaryColor)),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(controller: titleController, style: const TextStyle(color: textPrimaryColor), decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: textSecondaryColor)), validator: (val) => val!.isEmpty ? 'Enter a title' : null),
                      TextFormField(controller: descriptionController, style: const TextStyle(color: textPrimaryColor), decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: textSecondaryColor))),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.calendar_today, color: primaryActionColor),
                            label: Text(selectedDate == null ? 'Select Date' : DateFormat.yMd().format(selectedDate!), style: const TextStyle(color: primaryActionColor)),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
                              if (pickedDate != null) {
                                setDialogState(() => selectedDate = pickedDate);
                              }
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.access_time, color: primaryActionColor),
                            label: Text(selectedTime == null ? 'Select Time' : selectedTime!.format(context), style: const TextStyle(color: primaryActionColor)),
                            onPressed: () async {
                              final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                              if (pickedTime != null) {
                                setDialogState(() => selectedTime = pickedTime);
                              }
                            },
                          ),
                        ],
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
                        if (selectedDate == null || selectedTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date and time for the plan.')));
                          return;
                        }
                        final planDateTime = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, selectedTime!.hour, selectedTime!.minute);
                        _savePlan(title: titleController.text.trim(), description: descriptionController.text.trim(), time: Timestamp.fromDate(planDateTime));
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  Future<void> _savePlan({required String title, required String description, required Timestamp time}) async {
    final newPlan = Plan(
      id: '',
      title: title,
      description: description,
      time: time,
      createdAt: Timestamp.now(),
    );

    try {
      await FirebaseFirestore.instance.collection('trips').doc(widget.trip.id).collection('plans').add(newPlan.toMap());
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add plan: $e')));
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: darkBackgroundColor,
          title: const Text('Delete Trip?', style: TextStyle(color: textPrimaryColor)),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This action is permanent and cannot be undone.', style: TextStyle(color: textSecondaryColor)),
                Text('All associated plans and expenses will also be deleted.', style: TextStyle(color: textSecondaryColor)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: textSecondaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Delete', style: TextStyle(color: textPrimaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTrip();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTrip() async {
    try {
      final tripRef = FirebaseFirestore.instance.collection('trips').doc(widget.trip.id);
      final expenses = await tripRef.collection('expenses').get();
      for (final doc in expenses.docs) {
        await doc.reference.delete();
      }
      final plans = await tripRef.collection('plans').get();
      for (final doc in plans.docs) {
        await doc.reference.delete();
      }
      await tripRef.delete();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete trip: $e')),
        );
      }
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
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: _showDeleteConfirmationDialog,
                  tooltip: 'Delete Trip',
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddTripsPage(tripToEdit: widget.trip))),
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
        // --- MODIFIED: Show a loader while names are being fetched ---
        body: _isLoadingNames
            ? const Center(child: CircularProgressIndicator(color: primaryActionColor))
            : TabBarView(
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
        tooltip: _tabController.index == 1 ? 'Add Plan' : 'Add Expense',
        child: Icon(_tabController.index == 1 ? Icons.event_note : Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  Widget _buildExpensesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').doc(widget.trip.id).collection('expenses').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: textPrimaryColor)));
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text('No expenses added yet.', style: TextStyle(color: textSecondaryColor)));
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('trips').doc(widget.trip.id).collection('plans').orderBy('time').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.edit_calendar, size: 60, color: textSecondaryColor), const SizedBox(height: 16), const Text('No plans added yet.', style: TextStyle(color: textSecondaryColor))]));
        }
        final plans = snapshot.data!.docs.map((doc) => Plan.fromFirestore(doc)).toList();
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            return Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: inputFieldFillColor, borderRadius: BorderRadius.circular(12.0)),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: textSecondaryColor, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat.jm().format(plan.time.toDate()), style: const TextStyle(color: textPrimaryColor)),
                        Text(plan.title, style: const TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        if(plan.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(plan.description, style: const TextStyle(color: textSecondaryColor))),
                      ],
                    ),
                  ),
                  TextButton(onPressed: (){}, child: const Text('Edit', style: TextStyle(color: primaryActionColor))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        BalanceSummaryCard(
          tripId: widget.trip.id,
          memberUids: widget.trip.members,
          memberNames: _memberNames,
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
          title: Text('More features coming soon!', style: TextStyle(color: textPrimaryColor)),
          trailing: Text('Settle Up', style: TextStyle(color: primaryActionColor)),
        ),
      ],
    );
  }
}