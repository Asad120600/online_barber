import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:online_barber_app/push_notification_service.dart';
// Import your push notification service
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class ChatScreen extends StatefulWidget {
  final String threadId;

  const ChatScreen({super.key, required this.threadId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Add scroll controller

  @override
  void initState() {
    super.initState();
    // Scroll to the bottom when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.admin),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('contactUs')
                  .doc(widget.threadId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                // Scroll to the bottom whenever the messages update
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController, // Attach controller to ListView
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isAdmin = message['sender'] == 'admin';

                    return Align(
                      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.grey[300] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          message['text'],
                          style: TextStyle(
                            color: isAdmin ? Colors.black : Colors.blue,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await _sendMessage(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(BuildContext context) async {
    if (_messageController.text.isEmpty) {
      return;
    }

    try {
      // Add the message to Firestore
      await FirebaseFirestore.instance
          .collection('contactUs')
          .doc(widget.threadId)
          .collection('messages')
          .add({
        'text': _messageController.text,
        'sender': 'user', // Change to 'admin' if needed
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false, // New messages are unread by default
      });

      // Fetch the admin's device token
      String adminToken = await _fetchAdminToken();

      if (adminToken.isNotEmpty) {
        // Send notification to the admin
        PushNotificationService.sendNotification(
          adminToken,
          context,
          'New Message Received',
          'Subject: ${_messageController.text}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin token not found. Notification not sent.')),
        );
      }

      _messageController.clear();
      _scrollToBottom(); // Scroll to the bottom after sending a message
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message. Please try again.')),
      );
    }
  }

  Future<String> _fetchAdminToken() async {
    try {
      // Fetch the admin document from Firestore
      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc('OEQj3lxQnPcdcyeuJEIsm9MxDWx1') // Replace with the actual UID
          .get();

      if (adminSnapshot.exists) {
        return adminSnapshot['token'] ?? ''; // Return the admin's FCM token
      } else {
        print('Admin not found');
        return '';
      }
    } catch (e) {
      print('Error fetching admin token: $e');
      return '';
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
