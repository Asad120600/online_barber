import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:online_barber_app/models/notification_model.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/user/Drawer%20Pages/order_notifications.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class NotificationsScreen extends StatelessWidget {
  final String uid;

  const NotificationsScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,  // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title:  Text(localizations.notifications),
          bottom:  TabBar(
            tabs: [
              Tab(text: localizations.g_notifications,),  // General Notifications
              Tab(text: localizations.o_notifications),    // Order Notifications
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OtherNotificationsTab(uid: LocalStorage().getCurrentUserId()),  // Pass the uid to the other notifications tab
            OrderNotificationsTab(uid:  LocalStorage().getCurrentUserId()),  // Pass the uid to the order notifications tab
          ],
        ),
      ),
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
          return const Center(child: LoadingDots());
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
        .doc(uid) // Use the provided uid to filter notifications
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
