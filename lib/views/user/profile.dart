import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User? _currentUser;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  String? _firstName; // Variable to hold the first name
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _firstName = _currentUser?.displayName; // Initialize first name after _currentUser is assigned
    _phoneController = TextEditingController(text: _currentUser?.phoneNumber ?? '');
    _dobController = TextEditingController(text: ''); // Initialize with current DOB if available
    _fetchProfileData();
  }

  void _fetchProfileData() async {
    // Fetch additional profile data from Firestore if needed
    try {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(_currentUser?.uid).get();
      if (snapshot.exists) {
        setState(() {
          _firstName = snapshot['firstName'] ?? 'User';
          _phoneController.text = snapshot['phone'] ?? '';
          _dobController.text = snapshot['dob'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  void _updateProfile() async {
    try {
      await _firestore.collection('users').doc(_currentUser?.uid).set({
        'phone': _phoneController.text,
        'dob': _dobController.text,
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch the viewInsets (keyboard space) from MediaQuery
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: viewInsets.bottom), // Add padding equal to the bottom viewInsets
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_currentUser?.photoURL ?? ''),
                backgroundColor: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                _firstName ?? 'User',
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
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  icon: Icon(Icons.phone, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  icon: Icon(Icons.cake, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 16),
              Button(
                onPressed: _updateProfile,
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 16), // Added some spacing to avoid hiding content under the keyboard
            ],
          ),
        ),
      ),
    );
  }
}
