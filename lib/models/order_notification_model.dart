import 'package:cloud_firestore/cloud_firestore.dart';

class OrderNotificationModel {
  final String message;
  final String body;
  final String orderId;
  final String userId;
  final DateTime timestamp;

  OrderNotificationModel({
    required this.message,
    required this.body,
    required this.orderId,
    required this.userId,
    required this.timestamp,
  });

  // Factory method to create NotificationModel from Firestore
  factory OrderNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderNotificationModel(
      message: data['message'] ?? '',
      body: data['body'] ?? '',
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
