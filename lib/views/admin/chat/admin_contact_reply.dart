import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:online_barber_app/views/admin/chat/reply_chat_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
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
              color: Colors.grey[300],
            ),
            itemBuilder: (context, index) {
              var thread = threads[index];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('contactUs')
                    .doc(thread.id)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, messageSnapshot) {
                  if (!messageSnapshot.hasData) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: Icon(Icons.person, color: Colors.grey[700]),
                      ),
                      title: const Text('Loading user email...'),
                      subtitle: const Text('Loading latest message...'),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    );
                  }

                  var latestMessageDoc = messageSnapshot.data!.docs.isNotEmpty
                      ? messageSnapshot.data!.docs.first
                      : null;
                  var latestMessage = latestMessageDoc?['text'];
                  var sender = latestMessageDoc?['sender'] ?? 'Unknown';
                  var timestamp = latestMessageDoc?['timestamp']?.toDate();
                  var isRead = latestMessageDoc?['isRead'] ?? true;

                  return FutureBuilder<Map<String, dynamic>>(
                    future: _getUserData(thread),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            child: Icon(Icons.person, color: Colors.grey[700]),
                          ),
                          title: const Text('Loading user email...'),
                          subtitle: Text('$sender: Loading message...'),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        );
                      }

                      var data = userSnapshot.data!;
                      String preview = latestMessage ?? 'No messages yet';
                      String userEmail = data['userEmail'] ?? 'Unknown';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: Icon(Icons.person, color: Colors.grey[700]),
                        ),
                        title: Text(userEmail),
                        subtitle: Text('$sender: $preview'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isRead)
                              const Icon(Icons.circle, color: Colors.green, size: 10),
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        onTap: () async {
                          if (!isRead) {
                            await _markAsRead(thread.id);
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReplyScreen(
                                threadId: thread.id,
                                userId: data['userId'],
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
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getUserData(DocumentSnapshot thread) async {
    try {
      var userEmail = thread['email'];
      var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      var userDoc = userSnapshot.docs.isNotEmpty ? userSnapshot.docs.first : null;
      var userId = userDoc?.id ?? 'Unknown';

      return {
        'userEmail': userEmail,
        'userId': userId,
      };
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return {
        'userEmail': 'Unknown',
        'userId': 'Unknown',
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
      if (kDebugMode) {
        print(e);
      }
    }
  }
}
