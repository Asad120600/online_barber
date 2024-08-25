import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:online_barber_app/views/admin/reply_chat_screen.dart';

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

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.grey[700]),
                    ),
                    title: Text(userEmail), // Show user email
                    subtitle: Text(preview), // Show latest message
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    onTap: () {
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

  Future<Map<String, dynamic>> _getLatestMessageAndUserEmail(QueryDocumentSnapshot thread) async {
    try {
      // Fetch the latest message for the thread
      var messageSnapshot = await FirebaseFirestore.instance
          .collection('contactUs')
          .doc(thread.id)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      var latestMessage = messageSnapshot.docs.isNotEmpty ? messageSnapshot.docs.first['text'] : null;

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
      };
    } catch (e) {
      print(e);
      return {
        'latestMessage': null,
        'userEmail': 'Unknown',
        'userId': 'Unknown',
      };
    }
  }
}
