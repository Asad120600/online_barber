import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:online_barber_app/views/admin/chat/reply_chat_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('contactUs').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var threads = snapshot.data!.docs;

          return ListView.separated(
            itemCount: threads.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[300], // Light color for the divider
            ),
            itemBuilder: (context, index) {
              var thread = threads[index];

              // Fetch the latest message for the thread
              return FutureBuilder<Map<String, dynamic>>(
                future: _getLatestMessageAndUserEmail(thread),
                builder: (context, futureSnapshot) {
                  if (!futureSnapshot.hasData) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: Icon(Icons.person, color: Colors.grey[700]),
                      ),
                      title: Text('Loading user email...'),
                      subtitle: Text('Loading latest message...'),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    );
                  }

                  var data = futureSnapshot.data!;
                  String preview = data['latestMessage'] ?? 'No messages yet';
                  String userEmail = data['userEmail'] ?? 'Unknown';
                  String sender = data['sender'] ?? 'Unknown'; // Retrieve sender
                  DateTime? timestamp = data['timestamp']; // Retrieve timestamp
                  bool isRead = data['isRead'] ?? true; // Check if the message is read

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.grey[700]),
                    ),
                    title: Text(userEmail), // Show user email
                    subtitle: Text('$sender: $preview'), // Show sender and latest message
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isRead)
                          Icon(Icons.circle, color: Colors.green, size: 10), // Show green dot for unread messages
                        if (timestamp != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              DateFormat('hh:mm a').format(timestamp),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                      ],
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    onTap: () async {
                      // Mark the message as read when tapped
                      if (!isRead) {
                        await _markAsRead(thread.id);
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReplyScreen(
                            threadId: thread.id,
                            userId: data['userId'], // Pass the user ID to the ReplyScreen
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _refreshData() async {
    // No additional logic needed; StreamBuilder handles real-time updates
  }

  Future<Map<String, dynamic>> _getLatestMessageAndUserEmail(QueryDocumentSnapshot thread) async {
    try {
      // Fetch the latest message for the thread, regardless of who sent it
      var messageSnapshot = await FirebaseFirestore.instance
          .collection('contactUs')
          .doc(thread.id)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      var latestMessageDoc = messageSnapshot.docs.isNotEmpty ? messageSnapshot.docs.first : null;
      var latestMessage = latestMessageDoc?['text'];
      var sender = latestMessageDoc?['sender'] ?? 'Unknown'; // Assuming you have a sender field
      var timestamp = latestMessageDoc?['timestamp']?.toDate(); // Convert timestamp to DateTime
      var isRead = latestMessageDoc?['isRead'] ?? true; // Check if the message is read

      // Get the user's email from the thread document
      var userEmail = thread['email']; // Adjust based on your field name

      // Fetch the user document using the email
      var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      var userDoc = userSnapshot.docs.isNotEmpty ? userSnapshot.docs.first : null;
      var userId = userDoc?.id ?? 'Unknown';

      return {
        'latestMessage': latestMessage,
        'userEmail': userEmail,
        'userId': userId,
        'sender': sender, // Include the sender information
        'timestamp': timestamp, // Include the timestamp
        'isRead': isRead, // Include the read status
      };
    } catch (e) {
      print(e);
      return {
        'latestMessage': null,
        'userEmail': 'Unknown',
        'userId': 'Unknown',
        'sender': 'Unknown',
        'timestamp': null,
        'isRead': true, // Default to read if there's an error
      };
    }
  }

  Future<void> _markAsRead(String threadId) async {
    try {
      var messageSnapshot = await FirebaseFirestore.instance
          .collection('contactUs')
          .doc(threadId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      var latestMessageDoc = messageSnapshot.docs.isNotEmpty ? messageSnapshot.docs.first : null;

      if (latestMessageDoc != null && !(latestMessageDoc['isRead'] ?? true)) {
        await latestMessageDoc.reference.update({'isRead': true});
      }
    } catch (e) {
      print(e);
    }
  }
}
