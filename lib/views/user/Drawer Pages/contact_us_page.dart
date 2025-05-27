import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:online_barber_app/push_notification_service.dart';
import 'package:online_barber_app/views/user/Drawer%20Pages/chat_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setUserEmail();
  }

  Future<void> _setUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? ''; // Set the email controller's text
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.contact_us),
        backgroundColor: Colors.orange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your message';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _submitForm(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm(BuildContext context) async {
    final contactData = {
      'subject': _subjectController.text,
      'name': _nameController.text,
      'email': _emailController.text,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending', // To track if admin has responded
    };

    try {
      // Add data to Firestore
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('contactUs')
          .add(contactData);

      // Add initial message with isRead field
      await docRef.collection('messages').add({
        'text': _messageController.text,
        'sender': 'user',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false, // Set the message as unread
      });

      // Fetch the admin's device token
      String adminToken = await _fetchAdminToken();

      if (adminToken.isNotEmpty) {
        // Send notification to the admin
        PushNotificationService.sendNotification(
          adminToken,
          context,
          'New Contact Us Message',
          'Subject: ${_subjectController.text}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin token not found. Notification not sent.')),
        );
      }

      // After successful submission, navigate to chat screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatScreen(threadId: docRef.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send your message. Please try again.')),
      );
    }
  }

  Future<String> _fetchAdminToken() async {
    try {
      // Get the UID for the admin
      const adminUid = 'OEQj3lxQnPcdcyeuJEIsm9MxDWx1'; // Replace with your admin UID if needed

      // Fetch the admin document from Firestore using the UID
      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminUid)
          .get();

      if (adminSnapshot.exists) {
        // Return the admin's FCM token
        return adminSnapshot['token'] ?? '';
      } else {
        print('Admin not found');
        return '';
      }
    } catch (e) {
      print('Error fetching admin token: $e');
      return '';
    }
  }
}
