// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:online_barber_app/models/notification_model.dart';
//
// class OrderNotificationsTab extends StatelessWidget {
//   final String uid;
//
//   const OrderNotificationsTab({super.key, required this.uid});
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<List<NotificationModel>>(
//       stream: _getOrderNotificationsStream(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Center(child: Text('No order notifications found.'));
//         } else {
//           List<NotificationModel> notifications = snapshot.data!;
//
//           return ListView.builder(
//             itemCount: notifications.length,
//             itemBuilder: (context, index) {
//               NotificationModel notification = notifications[index];
//               return Card(
//                 margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(16),
//                   title: Text(
//                     notification.title,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(notification.body),
//                       const SizedBox(height: 4),
//                       Text(
//                         'User ID: ${notification.userId}', // Display user ID
//                         style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
//                       ),
//                     ],
//                   ),
//                   trailing: Text(DateFormat('dd/MM/yyyy').format(notification.date)),
//                   onTap: () {},
//                 ),
//               );
//             },
//           );
//         }
//       },
//     );
//   }
//
//   // Stream to get only the current user's order notifications
//   Stream<List<NotificationModel>> _getOrderNotificationsStream() {
//     return FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid) // Filter by specific user ID
//         .collection('notifications')
//         .where('type', isEqualTo: 'order') // Filter by type 'order'
//         .snapshots()
//         .asyncMap((notificationSnapshot) async {
//       // Convert Firestore documents to NotificationModel
//       List<NotificationModel> notifications = notificationSnapshot.docs
//           .map((doc) => NotificationModel.fromFirestore(doc))
//           .toList();
//
//       // Sort notifications by date
//       notifications.sort((a, b) => b.date.compareTo(a.date));
//
//       return notifications;
//     });
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:online_barber_app/models/notification_model.dart';

class OrderNotificationsTab extends StatelessWidget {
  final String uid;

  const OrderNotificationsTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationModel>>(
      stream: _getOrderNotificationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No order notifications found.'));
        } else {
          List<NotificationModel> notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              NotificationModel notification = notifications[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    notification.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.body),
                      const SizedBox(height: 4),
                      Text(
                        'User ID: ${notification.userId}', // Display user ID
                        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Text(DateFormat('dd/MM/yyyy').format(notification.date)),
                  onTap: () {
                    // You can add actions when tapping on a notification
                  },
                ),
              );
            },
          );
        }
      },
    );
  }

  // Stream to get only the current user's order notifications
  Stream<List<NotificationModel>> _getOrderNotificationsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid) // Filter by specific user ID
        .collection('notifications')
        .where('type', isEqualTo: 'order') // Filter by type 'order'
        .where('userId', isEqualTo: uid) // Ensure the userId matches the current user
        .snapshots()
        .asyncMap((notificationSnapshot) async {
      // Convert Firestore documents to NotificationModel
      List<NotificationModel> notifications = notificationSnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();

      // Sort notifications by date
      notifications.sort((a, b) => b.date.compareTo(a.date));

      return notifications;
    });
  }
}
