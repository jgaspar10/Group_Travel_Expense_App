// lib/pages/trip_overview_page.dart
import 'package:flutter/material.dart';
import '../models/trip_model.dart'; // Make sure this path is correct

// Your existing color constants from other files
const Color darkBackgroundColor = Color(0xFF204051);
const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color primaryActionColor = Color(0xFF4AB19D); // Teal accent
const Color inputFieldFillColor = Color(0xFF2A4A5A); // Lighter dark color
const Color actionButtonColor = Colors.blue; // Example blue from screenshot

class TripOverviewPage extends StatefulWidget {
  final Trip trip;

  const TripOverviewPage({super.key, required this.trip});

  @override
  State<TripOverviewPage> createState() => _TripOverviewPageState();
}

class _TripOverviewPageState extends State<TripOverviewPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              floating: false,
              pinned: true,
              backgroundColor: darkBackgroundColor,
              iconTheme: const IconThemeData(color: textPrimaryColor),
              actions: [
                // Edit button on the app bar
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to the AddTripsPage in edit mode
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.3),
                    shape: const CircleBorder(),
                  ),
                  child: const Text('Edit', style: TextStyle(color: textPrimaryColor)),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, right: 20, bottom: 50),
                centerTitle: false,
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.trip.title,
                      style: const TextStyle(
                        color: textPrimaryColor,
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.trip.date, // This shows the date range
                      style: const TextStyle(
                        color: textSecondaryColor,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
                background: Hero(
                  tag: 'trip_image_${widget.trip.id}', // Connects animation
                  child: Image.network(
                    widget.trip.imageUrl,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.4),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: textPrimaryColor,
                unselectedLabelColor: textSecondaryColor,
                indicatorColor: primaryActionColor,
                indicatorWeight: 3.0,
                tabs: const [
                  Tab(text: "Overview"),
                  Tab(text: "Plans"),
                  Tab(text: "Expenses"),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Overview Tab (with placeholder content from screenshot)
            _buildOverviewTab(),
            // Plans Tab (Placeholder)
            const Center(child: Text('Plans will be shown here.', style: TextStyle(color: textSecondaryColor))),
            // Expenses Tab (Placeholder)
            const Center(child: Text('A list of expenses will be shown here.', style: TextStyle(color: textSecondaryColor))),
          ],
        ),
      ),
    );
  }

  // Widget builder for the Overview tab content
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Placeholder for Spent/Budget
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: inputFieldFillColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Expenses', style: TextStyle(color: textPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Spent: \$12,500 of \$25,000', style: TextStyle(color: textSecondaryColor)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 0.5,
                  backgroundColor: textSecondaryColor.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryActionColor),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Placeholder for an activity card
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: inputFieldFillColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: textSecondaryColor, size: 28),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('09:00 AM', style: TextStyle(color: textPrimaryColor)),
                    Text('Bike Ride To Pan-Gong Lake', style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Start early, pack lunch', style: TextStyle(color: textSecondaryColor)),
                  ],
                ),
              ),
              TextButton(onPressed: (){}, child: const Text('Edit')),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Placeholder for the "Add Expense" button
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, color: textPrimaryColor),
          label: const Text('Add Expense', style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: actionButtonColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          ),
        ),
        const SizedBox(height: 24),
        // Placeholder for "Action Items"
        const Text('Action Items', style: TextStyle(color: textPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(backgroundColor: Colors.blue), // Placeholder avatar
          title: const Text('Ravi owes you \$1,000', style: TextStyle(color: textPrimaryColor)),
          trailing: const Text('Settle Now >', style: TextStyle(color: primaryActionColor)),
        ),
      ],
    );
  }
}
