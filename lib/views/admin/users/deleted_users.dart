import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DeletedUsers extends StatelessWidget {
  const DeletedUsers({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.deleted_users),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('deleted_users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('${localizations.error}: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return Center(
              child: Text(localizations.no_deleted_users),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              final deletedAtTimestamp = data['deleted_at'];

              DateTime? deletedAt;
              String formattedDate = localizations.no_date;
              String formattedTime = localizations.no_time;

              if (deletedAtTimestamp != null) {
                deletedAt = (deletedAtTimestamp as Timestamp).toDate();
                formattedDate = DateFormat('dd/MM/yy').format(deletedAt);
                formattedTime = DateFormat('hh:mm a').format(deletedAt);
              }

              final email = data['email'] ?? localizations.no_email;
              final firstName = data['firstName'] ?? localizations.no_first_name;
              final lastName = data['lastName'] ?? localizations.no_last_name;
              final userType = data['userType'] ?? localizations.no_user_type;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(
                    '$firstName $lastName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text('${localizations.deleted_at}: $formattedDate $formattedTime'),
                      Text('${localizations.email}: $email'),
                      Text('${localizations.user_type}: $userType'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.restore),
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
