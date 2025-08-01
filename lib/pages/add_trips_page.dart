// lib/pages/add_trips_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/trip_model.dart';
import '../services/storage_service.dart';

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
  final _budgetController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  File? _tripImageFile;
  Map<String, String> _membersInfo = {};
  List<String> _invitedEmails = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.tripToEdit != null) {
      final trip = widget.tripToEdit!;
      _titleController.text = trip.title;
      _descriptionController.text = trip.location;
      _startDate = trip.startDate.toDate();
      _endDate = trip.endDate.toDate();
      _startDateController.text = DateFormat('dd MMMM yyyy').format(_startDate!);
      _endDateController.text = DateFormat('dd MMMM yyyy').format(_endDate!);
      _budgetController.text = trip.budget.toStringAsFixed(2);
      _invitedEmails = List<String>.from(trip.invitedEmails);
      if (trip.members.isNotEmpty) {
        _fetchMemberInfo(trip.members);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _fetchMemberInfo(List<String> memberUIDs) async {
    if (memberUIDs.isEmpty) return;
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: memberUIDs).get();
      final Map<String, String> fetchedInfo = {};
      for (var doc in usersSnapshot.docs) {
        fetchedInfo[doc.id] = doc.data()['email'] ?? 'Unknown User';
      }
      if (mounted) {
        setState(() {
          _membersInfo = fetchedInfo;
        });
      }
    } catch (e) {
      print("Error fetching member info: $e");
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: primaryActionColor, onPrimary: textPrimaryColor, surface: darkBackgroundColor, onSurface: textPrimaryColor),
            dialogBackgroundColor: darkBackgroundColor,
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primaryActionColor)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final DateFormat formatter = DateFormat('dd MMMM yyyy');
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = formatter.format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = formatter.format(picked);
        }
      });
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) { return; }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a start and end date.')));
      return;
    }

    setState(() { _isUploading = true; });

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _isUploading = false; });
      return;
    }

    if (!_membersInfo.containsKey(user.uid)) {
      _membersInfo[user.uid] = user.email ?? 'Creator';
    }

    String imageUrl = widget.tripToEdit?.imageUrl ?? 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=60';
    if (_tripImageFile != null) {
      final String? uploadedUrl = await StorageService().uploadTripImage(_tripImageFile!);
      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image upload failed. Please try again.')));
        setState(() { _isUploading = false; });
        return;
      }
    }

    try {
      final List<String> memberUIDs = _membersInfo.keys.toList();
      final shareCode = widget.tripToEdit?.shareCode ?? const Uuid().v4().substring(0, 6).toUpperCase();
      final tripId = widget.tripToEdit?.id ?? FirebaseFirestore.instance.collection('trips').doc().id;

      final newTrip = Trip(
        id: tripId,
        title: _titleController.text,
        location: _descriptionController.text,
        startDate: Timestamp.fromDate(_startDate!),
        endDate: Timestamp.fromDate(_endDate!),
        imageUrl: imageUrl,
        members: memberUIDs,
        invitedEmails: _invitedEmails,
        shareCode: shareCode,
        budget: double.tryParse(_budgetController.text) ?? 0.0,
        createdAt: widget.tripToEdit?.createdAt ?? Timestamp.now(),
      );

      await FirebaseFirestore.instance.collection('trips').doc(tripId).set(newTrip.toMap());

      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save trip: $e')));
    } finally {
      if (mounted) {
        setState(() { _isUploading = false; });
      }
    }
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

  void _addMember() { _showAddMemberByEmailDialog(); }

  Future<void> _showAddMemberByEmailDialog() async {
    final emailController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: darkBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: const Text('Add Member by Email', style: TextStyle(color: textPrimaryColor)),
          content: Form(key: dialogFormKey, child: TextFormField(controller: emailController, autofocus: true, style: const TextStyle(color: textPrimaryColor), decoration: const InputDecoration(hintText: "Enter member's email", hintStyle: TextStyle(color: textSecondaryColor)), validator: (value) => (value == null || !value.contains('@')) ? 'Please enter a valid email.' : null)),
          actions: <Widget>[
            TextButton(child: const Text('Cancel', style: TextStyle(color: textSecondaryColor)), onPressed: () => Navigator.of(dialogContext).pop()),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryActionColor),
              child: const Text('Invite', style: TextStyle(color: primaryActionTextColor)),
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  final email = emailController.text.trim();
                  Navigator.of(dialogContext).pop();
                  _showInviteConfirmationDialog(email);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showInviteConfirmationDialog(String email) async {
    return showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: darkBackgroundColor,
            title: const Text('Send Invitation?', style: TextStyle(color: textPrimaryColor)),
            content: Text('This will prepare an email invitation for "$email" containing the trip\'s share code.', style: const TextStyle(color: textSecondaryColor)),
            actions: [
              TextButton(child: const Text('Cancel', style: TextStyle(color: textSecondaryColor)), onPressed: () => Navigator.of(dialogContext).pop()),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryActionColor),
                child: const Text('Send Invite', style: TextStyle(color: primaryActionTextColor)),
                onPressed: () {
                  setState(() {
                    if (!_invitedEmails.contains(email)) {
                      _invitedEmails.add(email);
                    }
                  });
                  _sendInviteEmail(email);
                  Navigator.of(dialogContext).pop();
                },
              )
            ],
          );
        });
  }

  Future<void> _sendInviteEmail(String email) async {
    final shareCode = widget.tripToEdit?.shareCode ?? const Uuid().v4().substring(0, 6).toUpperCase();
    final tripTitle = _titleController.text.isNotEmpty ? _titleController.text : "an upcoming trip";
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: email, query: 'subject=${Uri.encodeComponent('You\'ve been invited to join "$tripTitle"!')}&body=${Uri.encodeComponent('Hello!\n\nYou have been invited to join "$tripTitle".\n\nPlease sign up for our app and use the code below to join the group:\n\nShare Code: $shareCode\n\nThanks!')}');
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Could not launch email app';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch email app: $e')));
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
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: textPrimaryColor),
      maxLines: multiLine ? 3 : 1,
      readOnly: readOnly,
      keyboardType: keyboardType ?? (multiLine ? TextInputType.multiline : TextInputType.text),
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
                        : (widget.tripToEdit != null && widget.tripToEdit!.imageUrl.isNotEmpty && widget.tripToEdit!.imageUrl.startsWith('http'))
                        ? DecorationImage(image: NetworkImage(widget.tripToEdit!.imageUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: (_tripImageFile == null && !(widget.tripToEdit != null && widget.tripToEdit!.imageUrl.isNotEmpty && widget.tripToEdit!.imageUrl.startsWith('http')))
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
              _buildTextField(
                controller: _budgetController,
                label: 'Trip Budget (\$)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a budget';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(child: _buildTextField(controller: _startDateController, label: 'Trip Start Date', readOnly: true, onTap: () => _selectDate(context, true), validator: (value) => value!.isEmpty ? 'Select start date' : null, suffixIcon: IconButton(icon: const Icon(Icons.calendar_today_outlined, color: textSecondaryColor), onPressed: () => _selectDate(context, true)))),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('TO', style: TextStyle(color: textSecondaryColor, fontSize: 16))),
                  Expanded(child: _buildTextField(controller: _endDateController, label: 'Trip End Date', readOnly: true, onTap: () => _selectDate(context, false), validator: (value) => value!.isEmpty ? 'Select end date' : null, suffixIcon: IconButton(icon: const Icon(Icons.calendar_today_outlined, color: textSecondaryColor), onPressed: () => _selectDate(context, false)))),
                ],
              ),
              const SizedBox(height: 16),
              if (_membersInfo.isNotEmpty || _invitedEmails.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(color: inputFieldFillColor, borderRadius: BorderRadius.circular(8.0)),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      ..._membersInfo.entries.map((entry) => Chip(label: Text(entry.value, style: const TextStyle(color: textPrimaryColor)), backgroundColor: darkBackgroundColor, onDeleted: () => setState(() => _membersInfo.remove(entry.key)), deleteIconColor: textSecondaryColor)),
                      ..._invitedEmails.map((email) => Chip(label: Text(email, style: const TextStyle(color: textSecondaryColor)), avatar: const Icon(Icons.mail_outline, size: 16, color: textSecondaryColor), backgroundColor: darkBackgroundColor, onDeleted: () => setState(() => _invitedEmails.remove(email)), deleteIconColor: textSecondaryColor)),
                    ],
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
                onPressed: _isUploading ? null : _saveTrip,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEditing ? 'Save Changes' : 'Add', style: const TextStyle(color: primaryActionTextColor)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}