import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:online_barber_app/views/user/Drawer%20Pages/chat_screen.dart';
import 'package:online_barber_app/views/user/Drawer%20Pages/contact_us_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  Future<void> _checkAndNavigateToContactUsPage(BuildContext context, String userEmail) async {
    // Check if a chat thread already exists for the user
    final existingThreads = await FirebaseFirestore.instance
        .collection('contactUs')
        .where('email', isEqualTo: userEmail)
        .get();

    if (existingThreads.docs.isNotEmpty) {
      // Show Snackbar if an existing thread is found
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please use the existing chat thread to contact admin.')),
      );
    } else {
      // Navigate to ContactUsPage if no existing thread is found
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ContactUsPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.my_chats),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _checkAndNavigateToContactUsPage(context, userEmail);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('contactUs')
            .where('email', isEqualTo: userEmail) // Use the dynamic email
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var threads = snapshot.data!.docs;

          return ListView.builder(
            itemCount: threads.length,
            itemBuilder: (context, index) {
              var thread = threads[index];

              // Fetch the latest message
              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('contactUs')
                    .doc(thread.id)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .get(),
                builder: (context, messageSnapshot) {
                  if (!messageSnapshot.hasData) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: Icon(Icons.person, color: Colors.grey[700]),
                      ),
                      title: const Text('admin'),
                      subtitle: const Text('Loading latest message...'),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    );
                  }

                  var latestMessage = messageSnapshot.data!.docs.isNotEmpty
                      ? messageSnapshot.data!.docs.first
                      : null;

                  String preview = latestMessage != null
                      ? latestMessage['text']
                      : 'No messages yet'; // Placeholder if no messages

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.grey[700]),
                    ),
                    title: const Text('admin'),
                    subtitle: Text(preview),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(threadId: thread.id),
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
}
