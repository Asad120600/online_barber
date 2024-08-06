import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/utils/alert_dialog.dart';
import 'package:online_barber_app/utils/loading_dialog.dart';
import 'package:online_barber_app/views/admin/admin_panel.dart';

import '../../utils/button.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({Key? key}) : super(key: key);

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
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
    _fetchAdminData();
  }

  void _fetchAdminData() async {
    try {
      DocumentSnapshot snapshot =
      await _firestore.collection('admins').doc(_currentUser?.uid).get();
      if (snapshot.exists) {
        setState(() {
          _phoneController.text = snapshot['phone'] ?? '';
          _firstNameController.text = snapshot['firstName'] ?? '';
          _lastNameController.text = snapshot['lastName'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching admin data: $e');
    }
  }

  void _updateAdminProfile() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: LoadingDialog(message: "Profile is Updating!"),
        );
      },
    );

    try {
      await _firestore.collection('admins').doc(_currentUser?.uid).set({
        'phone': _phoneController.text,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
      }, SetOptions(merge: true));

      // Dismiss the loading dialog
      Navigator.pop(context);

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
                MaterialPageRoute(builder: (context) => AdminPanel()),
              );
            },
          );
        },
      );
    } catch (e) {
      print('Error updating admin profile: $e');
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
              _firstNameController.text.isNotEmpty ? _firstNameController.text : 'Admin',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currentUser?.email ?? 'admin@gmail.com',
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
                icon: Icon(Icons.person, color: Colors.orange),
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
                icon: Icon(Icons.person, color: Colors.orange),
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
                icon: Icon(Icons.phone, color: Colors.orange),
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
