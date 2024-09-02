import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:online_barber_app/push_notification_service.dart';

class ReplyScreen extends StatefulWidget {
  final String threadId;
  final String userId;

  const ReplyScreen({super.key, required this.threadId, required this.userId});

  @override
  _ReplyScreenState createState() => _ReplyScreenState();
}

class _ReplyScreenState extends State<ReplyScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String userEmail = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
  }

  Future<void> _fetchUserEmail() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          userEmail = userSnapshot['email'] ?? 'No email';
        });
      } else {
        setState(() {
          userEmail = 'User not found';
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        userEmail = 'Error fetching email';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reply to $userEmail'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      bool isAdmin = message['sender'] == 'admin';
                      return Align(
                        alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isAdmin ? Colors.grey[300] : Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
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
                    child: TextFormField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        labelText: 'Your Reply',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await _sendReply(context);
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
      ),
    );
  }

  Future<void> _sendReply(BuildContext context) async {
    if (_replyController.text.isEmpty) {
      return;
    }

    try {
      // Add admin's reply to the thread
      await FirebaseFirestore.instance
          .collection('contactUs')
          .doc(widget.threadId)
          .collection('messages')
          .add({
        'text': _replyController.text,
        'sender': 'admin',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the thread status
      await FirebaseFirestore.instance
          .collection('contactUs')
          .doc(widget.threadId)
          .update({
        'status': 'replied',
      });

      // Get the user's device token from the 'users' collection using userId (uid)
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userSnapshot.exists) {
        String userToken = userSnapshot['token'];

        // Send notification to the user
        PushNotificationService.sendNotificationToUser(
          userToken, context, 'Reply to your message', _replyController.text,
        );
      } else {
        // Handle the case where the user document does not exist
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found. Unable to send notification.')),
        );
      }

      // Clear the text field
      _replyController.clear();

      // Scroll to the bottom after sending the message
      _scrollToBottom();
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send the reply. Please try again.')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
