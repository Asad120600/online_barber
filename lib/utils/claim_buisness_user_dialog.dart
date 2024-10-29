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
    Key? key,
    required this.barberName,
    required this.onSubmit,
    required this.adminUid,
  }) : super(key: key);

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

    // Fetch admin FCM token from the 'admins' collection using admin UID
    try {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(widget.adminUid)
          .get();

      if (adminDoc.exists) {
        String? adminToken = adminDoc.get('token');

        if (adminToken != null && adminToken.isNotEmpty) {
          // Send notification to the admin
          await PushNotificationService.sendNotification(
            adminToken,
            context,
            'New Claim Submitted',
            'A new business claim has been submitted for ${barberNameController.text}.',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification sent to admin.')),
          );
        } else {
          debugPrint('Admin FCM token is missing');
        }
      } else {
        debugPrint('Admin document not found');
      }
    } catch (e) {
      debugPrint('Error fetching admin FCM token: $e');
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }

    Navigator.of(context).pop();
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
            Text(
              'Status: $claimStatus',
              style: TextStyle(
                color: claimStatus == 'approved' ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
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
