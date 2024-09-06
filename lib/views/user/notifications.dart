import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:online_barber_app/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  final String uid;

  const NotificationsScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,  // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'General Notifications'),  // Show Other Notifications first
              Tab(text: 'Order Notifications'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OtherNotificationsTab(uid: 'some-uid'),  // Other Notifications tab
            OrderNotifications(),  // Order Notifications tab
          ],
        ),
      ),
    );
  }
}

class OrderNotifications extends StatelessWidget {
  const OrderNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notifications').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final notifications = snapshot.data?.docs;

        if (notifications == null || notifications.isEmpty) {
          return const Center(child: Text('No notifications available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index].data() as Map<String, dynamic>;
            final orderId = notification['orderId'] ?? 'N/A';
            final message = notification['message'] ?? 'No message available';
            final notificationBody = notification['body'] ?? 'No details available';

            return Card(
              elevation: 4.0,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: ListTile(
                title: Text('Order ID: $orderId'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Message: $message'),
                    Text('Details: $notificationBody'),
                  ],
                ),
                leading: const CircleAvatar(
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.notifications),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class OtherNotificationsTab extends StatelessWidget {
  final String uid;

  const OtherNotificationsTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationModel>>(
      stream: _getNotificationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No notifications found.'));
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
                  subtitle: Text(notification.body),
                  trailing: Text(DateFormat('dd/MM/yyyy').format(notification.date)),
                  onTap: () {},
                ),
              );
            },
          );
        }
      },
    );
  }

  Stream<List<NotificationModel>> _getNotificationsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .snapshots()
        .asyncMap((notificationSnapshot) async {
      // Fetch announcements from a separate collection
      final announcementSnapshot = await FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('timestamp', descending: true)
          .get();

      // Convert Firestore documents to NotificationModel
      List<NotificationModel> notifications = notificationSnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();

      notifications.addAll(
        announcementSnapshot.docs.map((doc) => NotificationModel.fromAnnouncementFirestore(doc)),
      );

      // Sort notifications by date
      notifications.sort((a, b) => b.date.compareTo(a.date));

      return notifications;
    });
  }
}
