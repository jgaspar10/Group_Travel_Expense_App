// lib/pages/add_trips_page.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';

// Dark Theme Colors
const Color darkBackgroundColor = Color(0xFF204051);
const Color textPrimaryColor = Colors.white;
const Color textSecondaryColor = Colors.white70;
const Color inputFieldFillColor = Color(0xFF2A4A5A);
const Color primaryActionColor = Color(0xFF4AB19D);
const Color primaryActionTextColor = Colors.white;

class AddTripsPage extends StatefulWidget {
  final Trip? tripToEdit;
  const AddTripsPage({super.key, this.tripToEdit});

  @override
  State<AddTripsPage> createState() => _AddTripsPageState();
}

class _AddTripsPageState extends State<AddTripsPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  File? _tripImageFile;
  List<String> _members = [];

  @override
  void initState() {
    super.initState();
    if (widget.tripToEdit != null) {
      final trip = widget.tripToEdit!;
      _titleController.text = trip.title;
      _descriptionController.text = trip.location;
      _startDateController.text = trip.date;
      _members = List<String>.from(trip.members);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _tripImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: primaryActionColor,
              onPrimary: textPrimaryColor,
              surface: darkBackgroundColor,
              onSurface: textPrimaryColor,
            ),
            dialogBackgroundColor: darkBackgroundColor,
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primaryActionColor)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final DateFormat formatter = DateFormat('dd MMMM yyyy');
      controller.text = formatter.format(picked);
    }
  }

  void _addMember() {
    _showAddMemberDialog();
  }

  Future<void> _showAddMemberDialog() async {
    final nameController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: darkBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: const Text('Add Member', style: TextStyle(color: textPrimaryColor)),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: textPrimaryColor),
              decoration: const InputDecoration(
                hintText: "Enter member's name",
                hintStyle: TextStyle(color: textSecondaryColor),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name.';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: textSecondaryColor)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryActionColor),
              child: const Text('Add', style: TextStyle(color: primaryActionTextColor)),
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  setState(() {
                    _members.add(nameController.text.trim());
                  });
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in.')));
      return;
    }

    if (!_members.contains(user.uid)) {
      _members.insert(0, user.uid);
    }

    String imageUrl = widget.tripToEdit?.imageUrl ?? 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=60';
    if (_tripImageFile != null) {
      // TODO: Implement actual image upload to Firebase Storage and get URL
      imageUrl = _tripImageFile!.path; // This is a local path, will be replaced later
    }

    try {
      if (widget.tripToEdit == null) {
        // ADDING A NEW TRIP
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        final random = Random.secure();
        final String shareCode = String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

        final newTrip = Trip(
          id: '',
          title: _titleController.text,
          location: _descriptionController.text,
          date: _startDateController.text,
          imageUrl: imageUrl,
          amount: "0\$",
          members: _members,
          shareCode: shareCode,
        );

        DocumentReference docRef = await FirebaseFirestore.instance.collection('trips').add(newTrip.toMap());
        await docRef.update({'id': docRef.id});
      } else {
        // UPDATING AN EXISTING TRIP
        final updatedData = {
          'title': _titleController.text,
          'location': _descriptionController.text,
          'date': _startDateController.text,
          'imageUrl': imageUrl,
          'members': _members,
        };
        await FirebaseFirestore.instance.collection('trips').doc(widget.tripToEdit!.id).update(updatedData);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save trip: $e')));
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool multiLine = false,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: textPrimaryColor),
      maxLines: multiLine ? 3 : 1,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textSecondaryColor),
        filled: true,
        fillColor: inputFieldFillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: primaryActionColor, width: 1.5)),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.tripToEdit != null;

    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isEditing ? 'Edit Trip' : 'Add Trip', style: const TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: inputFieldFillColor,
                    borderRadius: BorderRadius.circular(12.0),
                    image: _tripImageFile != null
                        ? DecorationImage(image: FileImage(_tripImageFile!), fit: BoxFit.cover)
                        : (isEditing && widget.tripToEdit!.imageUrl.isNotEmpty && widget.tripToEdit!.imageUrl.startsWith('http'))
                        ? DecorationImage(image: NetworkImage(widget.tripToEdit!.imageUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: (_tripImageFile == null && !(isEditing && widget.tripToEdit!.imageUrl.isNotEmpty && widget.tripToEdit!.imageUrl.startsWith('http')))
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 50, color: textSecondaryColor),
                        SizedBox(height: 8),
                        Text('Tap to add background', style: TextStyle(color: textSecondaryColor)),
                      ],
                    ),
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(controller: _titleController, label: 'Trip Title', validator: (value) => value!.isEmpty ? 'Please enter a trip title' : null),
              const SizedBox(height: 16),
              _buildTextField(controller: _descriptionController, label: 'Trip Description', multiLine: true),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(child: _buildTextField(controller: _startDateController, label: 'Trip Start Date', readOnly: true, onTap: () => _selectDate(context, _startDateController), validator: (value) => value!.isEmpty ? 'Select start date' : null, suffixIcon: IconButton(icon: const Icon(Icons.calendar_today_outlined, color: textSecondaryColor), onPressed: () => _selectDate(context, _startDateController)))),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('TO', style: TextStyle(color: textSecondaryColor, fontSize: 16))),
                  Expanded(child: _buildTextField(controller: _endDateController, label: 'Trip End Date', readOnly: true, onTap: () => _selectDate(context, _endDateController), validator: (value) => value!.isEmpty ? 'Select end date' : null, suffixIcon: IconButton(icon: const Icon(Icons.calendar_today_outlined, color: textSecondaryColor), onPressed: () => _selectDate(context, _endDateController)))),
                ],
              ),
              const SizedBox(height: 16),
              if (_members.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(color: inputFieldFillColor, borderRadius: BorderRadius.circular(8.0)),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _members.map((member) => Chip(
                      label: Text(member, style: const TextStyle(color: textPrimaryColor)),
                      backgroundColor: darkBackgroundColor,
                      onDeleted: () {
                        setState(() {
                          _members.remove(member);
                        });
                      },
                      deleteIconColor: textSecondaryColor,
                    )).toList(),
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(color: inputFieldFillColor, borderRadius: BorderRadius.circular(8.0)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Add Member', style: TextStyle(color: textPrimaryColor, fontSize: 16)),
                    IconButton(icon: const Icon(Icons.add_circle_outline, color: primaryActionColor), onPressed: _addMember),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryActionColor,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: _saveTrip,
                child: Text(isEditing ? 'Save Changes' : 'Add', style: const TextStyle(color: primaryActionTextColor)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
