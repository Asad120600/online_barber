import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/utils/alert_dialog.dart';
import 'package:online_barber_app/utils/loading_dialog.dart';
import 'package:online_barber_app/views/user/home_screen.dart';
import '../../utils/button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User? _currentUser;
  late TextEditingController _phoneController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _phoneController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _fetchProfileData();
  }

  void _fetchProfileData() async {
    log('Fetching profile data for user: ${_currentUser?.uid}');
    try {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(_currentUser?.uid).get();
      if (snapshot.exists) {
        log('Snapshot exists');
        setState(() {
          _firstNameController.text = snapshot['firstName'] ?? 'User';
          _lastNameController.text = snapshot['lastName'] ?? '';
          _phoneController.text = snapshot['phone'] ?? (_currentUser?.phoneNumber ?? '');
        });
        log('Fetched data: firstName: ${_firstNameController.text}, lastName: ${_lastNameController.text}, phone: ${_phoneController.text}');
      } else {
        log('Snapshot does not exist, using currentUser phone number');
        setState(() {
          _phoneController.text = _currentUser?.phoneNumber ?? '';
        });
      }
    } catch (e) {
      log('Error fetching profile data: $e');
      setState(() {
        _phoneController.text = _currentUser?.phoneNumber ?? '';
      });
    }
  }

  void _updateProfile() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: LoadingDialog(message: "Profile is Updating"),
        );
      },
    );

    try {
      await _firestore.collection('users').doc(_currentUser?.uid).set({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'phone': _phoneController.text,
      }, SetOptions(merge: true));

      // Dismiss the loading dialog
      Navigator.pop(context);

      // Show success dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: 'Success',
            content: 'Profile updated successfully',
            confirmButtonText: 'OK',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
          );
        },
      );

    } catch (e) {
      log('Error updating profile: $e');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _currentUser?.photoURL != null && _currentUser!.photoURL!.isNotEmpty
                    ? NetworkImage(_currentUser!.photoURL!)
                    : null,
                child: _currentUser?.photoURL == null || _currentUser!.photoURL!.isEmpty
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                _firstNameController.text.isNotEmpty ? _firstNameController.text : 'User',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentUser?.email ?? 'Email',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  icon: const Icon(Icons.person, color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0), // Adjust the radius as needed
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.orange), // Adjust the color as needed
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.grey), // Adjust the color as needed
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  icon: const Icon(Icons.person, color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0), // Adjust the radius as needed
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.orange), // Adjust the color as needed
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.grey), // Adjust the color as needed
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone, // Ensures only numerical input
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  icon: const Icon(Icons.phone, color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0), // Adjust the radius as needed
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.orange), // Adjust the color as needed
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.grey), // Adjust the color as needed
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Button(
                onPressed: _updateProfile,
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
