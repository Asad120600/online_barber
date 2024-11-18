import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/utils/alert_dialog.dart';
import 'package:online_barber_app/utils/loading_dialog.dart';
import 'package:online_barber_app/views/admin/admin_panel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    final localizations = AppLocalizations.of(context)!;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: LoadingDialog(message: localizations.profileUpdating),
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
            title: localizations.success,
            content: localizations.profileUpdated,
            confirmButtonText: 'OK',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminPanel()),
              );
            },
          );
        },
      );
    } catch (e) {
      print('Error updating admin profile: $e');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.failedToUpdate)),
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
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.profile),
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
              _firstNameController.text.isNotEmpty ? _firstNameController.text : localizations.admin,
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
                labelText: localizations.firstName,
                icon: const Icon(Icons.person, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: localizations.lastName,
                icon: const Icon(Icons.person, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: localizations.phoneNumber,
                icon: const Icon(Icons.phone, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 16),
            Button(
              onPressed: _updateAdminProfile,
              child: Text(localizations.saveChanges),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
