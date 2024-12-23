import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:online_barber_app/push_notification_service.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:online_barber_app/utils/loading_dots.dart'; // Import your LoadingDots widget

class ClaimBusinessDialog extends StatefulWidget {
  final String barberName;
  final Function(String, String, String, String, String, String) onSubmit;
  final String adminUid; // Pass the admin UID to fetch FCM token

  const ClaimBusinessDialog({
    super.key,
    required this.barberName,
    required this.onSubmit,
    required this.adminUid,
  });

  @override
  _ClaimBusinessDialogState createState() => _ClaimBusinessDialogState();
}

class _ClaimBusinessDialogState extends State<ClaimBusinessDialog> {
  final TextEditingController barberNameController = TextEditingController();
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();

  String claimStatus = 'pending'; // Default status
  bool isClaimed = false; // To check if business is already claimed
  bool isLoading = false; // To manage loading state

  @override
  void initState() {
    super.initState();
    barberNameController.text = widget.barberName;
    checkClaimStatus();
  }

  @override
  void dispose() {
    barberNameController.dispose();
    shopNameController.dispose();
    addressController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _sendNotificationToAdmin(String uid) async {
    try {
      // Fetch the admin document based on uid
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();

      if (adminDoc.exists) {
        var adminData = adminDoc.data() as Map<String, dynamic>;
        String adminToken = adminData['token'];

        log('Sending notification to admin with token: $adminToken'); // Debug log

        // Send notification to admin using PushNotificationService
        await PushNotificationService.sendNotification(
          adminToken,
          context,
          'New Claim Submitted',
          'A new business claim has been submitted for ${barberNameController.text}.',
        );
      } else {
        log('Admin document not found');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin document not found')),
        );
      }
    } catch (e) {
      log('Error sending notification to admin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending notification: ${e.toString()}')),
      );
    }
  }

  // Check if the business is already claimed
  Future<void> checkClaimStatus() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('claim_business')
          .where('barberName', isEqualTo: widget.barberName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var claim = snapshot.docs.first;
        setState(() {
          claimStatus = claim['status'] ?? 'pending';
          isClaimed = claimStatus == 'approved';
        });
      }
    } catch (e) {
      debugPrint('Error checking claim status: $e');
    }
  }

  Future<void> _submitClaim() async {
    if (isClaimed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This business has already been claimed.')),
      );
      return;
    }

    setState(() {
      isLoading = true; // Start loading
    });

    try {
      // Save claim to Firestore
      await FirebaseFirestore.instance.collection('claim_business').add({
        'barberName': barberNameController.text,
        'shopName': shopNameController.text,
        'address': addressController.text,
        'phoneNumber': phoneNumberController.text,
        'email': emailController.text,
        'nationalId': nationalIdController.text,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _sendNotificationToAdmin(widget.adminUid); // Pass the admin UID to send notification

      Navigator.of(context).pop();
    } catch (e) {
      log('Error submitting claim: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting claim: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Claim Business'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: barberNameController,
              decoration: const InputDecoration(labelText: 'Barber Name'),
              enabled: !isClaimed,
            ),
            TextField(
              controller: shopNameController,
              decoration: const InputDecoration(labelText: 'Shop Name'),
              enabled: !isClaimed,
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              enabled: !isClaimed,
            ),
            TextField(
              controller: phoneNumberController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              enabled: !isClaimed,
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              enabled: !isClaimed,
            ),
            TextField(
              controller: nationalIdController,
              decoration: const InputDecoration(labelText: 'National ID Card Number'),
              keyboardType: TextInputType.number,
              enabled: !isClaimed,
            ),
            const SizedBox(height: 10),
            if (isLoading) const LoadingDots(), // Show loading indicator if isLoading is true
          ],
        ),
      ),
      actions: [
        Button(
          width: 100,
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        Button(
          width: 100,
          onPressed: isClaimed ? null : _submitClaim,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
