// lib/pages/add_trips_page.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trip_model.dart';

// Your color constants...
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
  Map<String, String> _membersInfo = {};
  List<String> _invitedEmails = [];

  @override
  void initState() {
    super.initState();
    if (widget.tripToEdit != null) {
      final trip = widget.tripToEdit!;
      _titleController.text = trip.title;
      _descriptionController.text = trip.location;
      _startDateController.text = trip.date;
      _invitedEmails = List<String>.from(trip.invitedEmails);
      if (trip.members.isNotEmpty) {
        _fetchMemberInfo(trip.members);
      }
    }
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
            colorScheme: const ColorScheme.dark(primary: primaryActionColor, onPrimary: textPrimaryColor, surface: darkBackgroundColor, onSurface: textPrimaryColor),
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
    _showAddMemberByEmailDialog();
  }

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
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: emailController,
              autofocus: true,
              style: const TextStyle(color: textPrimaryColor),
              decoration: const InputDecoration(hintText: "Enter member's email", hintStyle: TextStyle(color: textSecondaryColor)),
              validator: (value) => (value == null || !value.contains('@')) ? 'Please enter a valid email.' : null,
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
              onPressed: () async {
                if (dialogFormKey.currentState!.validate()) {
                  final email = emailController.text.trim();

                  final querySnapshot = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();

                  if (mounted) {
                    if (querySnapshot.docs.isNotEmpty) {
                      final userDoc = querySnapshot.docs.first;
                      setState(() { _membersInfo[userDoc.id] = userDoc.data()['email']; });
                      Navigator.of(dialogContext).pop();
                    } else {
                      Navigator.of(dialogContext).pop();
                      _showInviteConfirmationDialog(email);
                    }
                  }
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
            title: const Text('User Not Found', style: TextStyle(color: textPrimaryColor)),
            content: Text('No user exists with the email "$email". Would you like to send them an email invitation to join this trip?', style: const TextStyle(color: textSecondaryColor)),
            actions: [
              TextButton(
                child: const Text('Cancel', style: TextStyle(color: textSecondaryColor)),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryActionColor),
                child: const Text('Send Invite', style: TextStyle(color: primaryActionTextColor)),
                onPressed: () {
                  setState(() {
                    if (!_invitedEmails.contains(email)) { _invitedEmails.add(email); }
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
    final shareCode = widget.tripToEdit?.shareCode ?? String.fromCharCodes(Iterable.generate(6, (_) => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.codeUnitAt(Random.secure().nextInt(36))));

    final tripTitle = _titleController.text.isNotEmpty ? _titleController.text : "an upcoming trip";

    final String subject = 'You\'ve been invited to join the trip "$tripTitle"!';
    final String body = 'Hello!\n\nYou have been invited to join "$tripTitle".\n\nPlease sign up for our app and use the code below to join the group:\n\nShare Code: $shareCode\n\nThanks!';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Could not launch $emailLaunchUri';
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch email app: $e')));
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) { return; }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in.')));
      return;
    }

    if (!_membersInfo.containsKey(user.uid)) {
      setState(() { _membersInfo[user.uid] = user.email ?? 'Creator'; });
    }

    final List<String> memberUIDs = _membersInfo.keys.toList();

    String imageUrl = widget.tripToEdit?.imageUrl ?? 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=60';
    if (_tripImageFile != null) { /* TODO: Image upload logic */ imageUrl = _tripImageFile!.path; }

    try {
      final String shareCode = widget.tripToEdit?.shareCode ?? String.fromCharCodes(Iterable.generate(6, (_) => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.codeUnitAt(Random.secure().nextInt(36))));

      if (widget.tripToEdit == null) {
        final newTrip = Trip(
          id: '', title: _titleController.text, location: _descriptionController.text, date: _startDateController.text,
          imageUrl: imageUrl, amount: "0\$", members: memberUIDs, invitedEmails: _invitedEmails, shareCode: shareCode,
        );
        DocumentReference docRef = await FirebaseFirestore.instance.collection('trips').add(newTrip.toMap());
        await docRef.update({'id': docRef.id});
      } else {
        final updatedData = {
          'title': _titleController.text, 'location': _descriptionController.text, 'date': _startDateController.text,
          'imageUrl': imageUrl, 'members': memberUIDs, 'invitedEmails': _invitedEmails,
        };
        await FirebaseFirestore.instance.collection('trips').doc(widget.tripToEdit!.id).update(updatedData);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save trip: $e')));
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
      keyboardType: multiLine ? TextInputType.multiline : TextInputType.text,
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
              if (_membersInfo.isNotEmpty || _invitedEmails.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(color: inputFieldFillColor, borderRadius: BorderRadius.circular(8.0)),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      ..._membersInfo.entries.map((entry) => Chip(
                        label: Text(entry.value, style: const TextStyle(color: textPrimaryColor)),
                        backgroundColor: darkBackgroundColor,
                        onDeleted: () => setState(() => _membersInfo.remove(entry.key)),
                        deleteIconColor: textSecondaryColor,
                      )),
                      ..._invitedEmails.map((email) => Chip(
                        label: Text(email, style: const TextStyle(color: textSecondaryColor)),
                        avatar: const Icon(Icons.mail_outline, size: 16, color: textSecondaryColor),
                        backgroundColor: darkBackgroundColor,
                        onDeleted: () => setState(() => _invitedEmails.remove(email)),
                        deleteIconColor: textSecondaryColor,
                      )),
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
