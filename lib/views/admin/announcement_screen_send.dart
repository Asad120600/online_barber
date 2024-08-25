import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:online_barber_app/push_notification_service.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  _AnnouncementScreenState createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  List<DocumentSnapshot> allUsers = []; // Store all users
  List<String> selectedUserTokens = []; // List of selected user tokens

  @override
  void initState() {
    super.initState();
    fetchAllUsers();
  }

  Future<void> fetchAllUsers() async {
    try {
      final firestore = FirebaseFirestore.instance.collection('users');
      final userSnapshots = await firestore.get();

      setState(() {
        allUsers = userSnapshots.docs;
      });
    } catch (e) {
      log("Failed to fetch users: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Announcement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 20),
            const Text('Select Users:'),
            Expanded(
              child: ListView.builder(
                itemCount: allUsers.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot user = allUsers[index];
                  String userName = user['firstName'];
                  String userToken = user['token']; // Assuming user tokens are stored in Firestore

                  return CheckboxListTile(
                    title: Text(userName),
                    value: selectedUserTokens.contains(userToken),
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected == true) {
                          if (!selectedUserTokens.contains(userToken)) {
                            selectedUserTokens.add(userToken);
                          }
                        } else {
                          selectedUserTokens.remove(userToken);
                        }
                        // Debug log
                        log('Selected User Tokens: $selectedUserTokens');
                      });
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                createAnnouncement(
                  _titleController.text,
                  _messageController.text,
                  context,
                );
              },
              child: const Text('Send Announcement'),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> createAnnouncement(String title, String message, BuildContext context) async {
    try {
      // Store the announcement in Firestore
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Notify selected users
      if (selectedUserTokens.isNotEmpty) {
        sendAnnouncementNotification(title, message, selectedUserTokens, context);
      }

      // Show success dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Announcement sent successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).pop(); // Close the AnnouncementScreen
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      log("Failed to send announcement: $e");
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send announcement: $e')),
      );
    }
  }

  void sendAnnouncementNotification(String title, String body, List<String> userTokens, BuildContext context) {
    for (String token in userTokens) {
      PushNotificationService.sendNotificationToUser(token, context, title, body);
    }
  }
}
