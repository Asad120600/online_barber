import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:online_barber_app/push_notification_service.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  _AnnouncementScreenState createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  List<DocumentSnapshot> allUsers = [];
  List<String> selectedUserTokens = [];
  bool selectAll = false;

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

  void toggleSelectAll() {
    setState(() {
      if (selectAll) {
        selectedUserTokens.clear();
      } else {
        selectedUserTokens = allUsers
            .map((user) => user['token'] as String)
            .toList();
      }
      selectAll = !selectAll;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.createAnnouncement),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.message),
            ),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.selectUsers, style: const TextStyle(fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: toggleSelectAll,
                  child: Text(selectAll ? AppLocalizations.of(context)!.deselectAll : AppLocalizations.of(context)!.selectAll),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: allUsers.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot user = allUsers[index];
                  String userName = user['firstName'];
                  String userToken = user['token'];

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
                        log('Selected User Tokens: $selectedUserTokens');
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Button(
                onPressed: () {
                  if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.pleaseEnterTitleMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    createAnnouncement(
                      _titleController.text,
                      _messageController.text,
                      context,
                    );
                  }
                },
                child: Text(AppLocalizations.of(context)!.sendAnnouncement),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> createAnnouncement(String title, String message, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (selectedUserTokens.isNotEmpty) {
        sendAnnouncementNotification(title, message, selectedUserTokens, context);
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.success),
            content: Text(AppLocalizations.of(context)!.announcementSent),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          );
        },
      );
    } catch (e) {
      log("Failed to send announcement: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedToSend( e.toString()))),
      );
    }
  }

  void sendAnnouncementNotification(String title, String body, List<String> userTokens, BuildContext context) {
    for (String token in userTokens) {
      PushNotificationService.sendNotificationToUser(token, context, title, body);
    }
  }
}
