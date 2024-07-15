import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User? _currentUser;
  late TextEditingController _phoneController;
  String? _firstName;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _firstName = _currentUser?.displayName;
    _phoneController = TextEditingController();
    _fetchProfileData();
  }

  void _fetchProfileData() async {
    print('Fetching profile data for user: ${_currentUser?.uid}');
    try {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(_currentUser?.uid).get();
      if (snapshot.exists) {
        print('Snapshot exists');
        setState(() {
          _firstName = snapshot['firstName'] ?? 'User';
          _phoneController.text = snapshot['phone'] ?? (_currentUser?.phoneNumber ?? '');
        });
        print('Fetched data: firstName: $_firstName, phone: ${_phoneController.text}');
      } else {
        print('Snapshot does not exist, using currentUser phone number');
        setState(() {
          _phoneController.text = _currentUser?.phoneNumber ?? '';
        });
      }
    } catch (e) {
      print('Error fetching profile data: $e');
      setState(() {
        _phoneController.text = _currentUser?.phoneNumber ?? '';
      });
    }
  }

  void _updateProfile() async {
    try {
      await _firestore.collection('users').doc(_currentUser?.uid).set({
        'phone': _phoneController.text,
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
              Text(
                _phoneController.text,
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
