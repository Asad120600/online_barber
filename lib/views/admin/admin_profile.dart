import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/button.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({Key? key}) : super(key: key);

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  late User? _currentUser;
  late TextEditingController _phoneController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _firstName;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _phoneController = TextEditingController();
    _fetchAdminData();
  }

  void _fetchAdminData() async {
    try {
      DocumentSnapshot snapshot =
      await _firestore.collection('admins').doc(_currentUser?.uid).get();
      if (snapshot.exists) {
        setState(() {
          _phoneController.text = snapshot['phone'] ?? '';
          _firstName = snapshot['firstName']; // Assuming 'firstname' is the field name in Firestore
        });
      }
    } catch (e) {
      print('Error fetching admin data: $e');
    }
  }

  void _updateAdminProfile() async {
    try {
      await _firestore.collection('admins').doc(_currentUser?.uid).set({
        'phone': _phoneController.text,
        'firstname': _firstName, // Update the 'firstname' field in Firestore
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      print('Error updating admin profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.orange,
              child: Icon(
                Icons.account_circle,
                size: 100,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _firstName ?? 'Admin ', // Display first name or fallback to 'Admin'
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currentUser?.email ?? 'admin@gmail.com', // Replace with admin's email
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
            Button(
              onPressed: _updateAdminProfile,
              child: const Text('Save Changes'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
