import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime date;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
  });

  // Factory constructor to create an instance from a general Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['message'] ?? data['body'] ?? '', // Handle both 'body' and 'message'
      date: (data['date'] ?? data['timestamp'] as Timestamp).toDate(), // Handle both 'date' and 'timestamp'
    );
  }

  // Factory constructor to create an instance from an announcement document
  factory NotificationModel.fromAnnouncementFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['message'] ?? '', // Assuming 'message' field in announcements
      date: (data['timestamp'] as Timestamp).toDate(), // Assuming 'timestamp' field in announcements
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'date': Timestamp.fromDate(date),
    };
  }

  // Factory method for order status updates
  factory NotificationModel.fromOrderStatusFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      title: data['status'] ?? 'Order Status Update',
      body: data['message'] ?? 'No details provided.',
      date: (data['timestamp'] as Timestamp).toDate(), id: '',
    );
  }
}


