import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/utils/loading_dots.dart';

class UserAnnouncementScreen extends StatelessWidget {
  const UserAnnouncementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Announcements'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('announcements').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return Center(child: LoadingDots());
          var announcements = snapshot.data!.docs;
          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              var announcement = announcements[index];
              return Card(
                child: ListTile(
                  title: Text(announcement['title']),
                  subtitle: Text(announcement['message']),
                  trailing: Icon( Icons.campaign),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
