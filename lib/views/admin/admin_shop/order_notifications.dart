import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminNotificationsPage extends StatefulWidget {
  @override
  _AdminNotificationsPageState createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('orders').get();
      List<Map<String, dynamic>> notifications = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Ensure 'products' field is a map with string keys and integer values
        Map<String, dynamic> products = Map<String, dynamic>.from(data['products']);

        notifications.add({
          'orderId': doc.id,
          'email': data['email'] ?? '',
          'firstName': data['firstName'] ?? '',
          'lastName': data['lastName'] ?? '',
          'phone': data['phone'] ?? '',
          'address': data['address'] ?? '',
          'products': products,
          'totalPrice': (data['totalPrice'] is String ? double.tryParse(data['totalPrice']) ?? 0.0 : data['totalPrice']) ?? 0.0,
          'orderDate': data['orderDate']?.toDate() ?? DateTime.now(),
        });
      }

      // Sort the notifications by 'orderDate' in descending order
      notifications.sort((a, b) => b['orderDate'].compareTo(a['orderDate']));

      return notifications;
    } catch (e) {
      log('Error fetching notifications: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Notifications'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No notifications available.'));
          }

          List<Map<String, dynamic>> notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification = notifications[index];
              var products = notification['products'] as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Order ID: ${notification['orderId']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${notification['email']}'),
                      Text('Name: ${notification['firstName']} ${notification['lastName']}'),
                      Text('Phone: ${notification['phone']}'),
                      Text('Address: ${notification['address']}'),
                      Text('Total Price: ${notification['totalPrice']}'), // Removed dollar sign
                      Text('Order Date: ${notification['orderDate'].toLocal()}'),
                      SizedBox(height: 8.0),
                      Text('Products:'),
                      ...products.entries.map((entry) {
                        String productId = entry.key;
                        int quantity = entry.value as int;

                        return FutureBuilder<DocumentSnapshot>(
                          future: _firestore.collection('products').doc(productId).get(),
                          builder: (context, productSnapshot) {
                            if (productSnapshot.connectionState == ConnectionState.waiting) {
                              return Text('Loading product details...');
                            }

                            if (productSnapshot.hasError || !productSnapshot.hasData) {
                              return Text('Error fetching product details');
                            }

                            var productData = productSnapshot.data!.data() as Map<String, dynamic>;
                            String description = productData['description'] ?? 'No description';
                            double price = (productData['price'] is String ? double.tryParse(productData['price']) ?? 0.0 : productData['price']) ?? 0.0;

                            return ListTile(
                              title: Text(description),
                              subtitle: Text('Quantity: $quantity'),
                              trailing: Text('${price * quantity}'), // Removed dollar sign
                            );
                          },
                        );
                      }).toList(),
                    ],
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
