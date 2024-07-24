import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting

class DeletedUsers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deleted Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('deleted_users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              final deletedAtTimestamp = data['deleted_at'];

              DateTime? deletedAt;
              String formattedDate = 'No Date';
              String formattedTime = 'No Time';

              if (deletedAtTimestamp != null) {
                deletedAt = (deletedAtTimestamp as Timestamp).toDate();
                formattedDate = DateFormat('dd/MM/yy').format(deletedAt);
                formattedTime = DateFormat('hh:mm a').format(deletedAt);
              }

              final email = data['email'] ?? 'No Email';
              final firstName = data['firstName'] ?? 'No First Name';
              final lastName = data['lastName'] ?? 'No Last Name';
              final userType = data['userType'] ?? 'No User Type';

              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(
                    '$firstName $lastName',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Text('Deleted at: $formattedDate $formattedTime'),
                      Text('Email: $email'),
                      Text('User Type: $userType'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.restore),
                    onPressed: () {
                      // Implement restore functionality if needed
                      // Example: Move user back to active users
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
