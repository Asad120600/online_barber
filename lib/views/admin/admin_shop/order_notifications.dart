import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

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
          'totalPrice': (data['totalPrice'] is String
              ? double.tryParse(data['totalPrice']) ?? 0.0
              : data['totalPrice']) ??
              0.0,
          'orderDate': data['orderDate']?.toDate() ?? DateTime.now(),
        });
      }

      // Sort the notifications by 'orderDate' in descending order
      notifications.sort((a, b) => b['orderDate'].compareTo(a['orderDate']));

      return notifications;
    } catch (e) {
      log(AppLocalizations.of(context)!.error_fetching_notifications(e.toString()));
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.order_notifications),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.error_fetching_notifications(snapshot.error.toString()),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.no_notifications_available));
          }

          List<Map<String, dynamic>> notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification = notifications[index];
              var products = notification['products'] as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(AppLocalizations.of(context)!.order_id(notification['orderId'])),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.email_e(notification['email'])),
                      Text(AppLocalizations.of(context)!.name(notification['firstName'], notification['lastName'])),
                      Text(AppLocalizations.of(context)!.phone_e(notification['phone'])),
                      Text(AppLocalizations.of(context)!.address_e(notification['address'])),
                      Text(AppLocalizations.of(context)!.total_price_e(notification['totalPrice'].toStringAsFixed(2))),
                      Text(AppLocalizations.of(context)!.order_date(notification['orderDate'].toLocal().toString())),
                      const SizedBox(height: 8.0),
                      Text(AppLocalizations.of(context)!.products),
                      ...products.entries.map((entry) {
                        String productId = entry.key;
                        int quantity = entry.value as int;

                        return FutureBuilder<DocumentSnapshot>(
                          future: _firestore.collection('products').doc(productId).get(),
                          builder: (context, productSnapshot) {
                            if (productSnapshot.connectionState == ConnectionState.waiting) {
                              return Text(AppLocalizations.of(context)!.loading_product_details);
                            }

                            if (productSnapshot.hasError || !productSnapshot.hasData) {
                              return Text(AppLocalizations.of(context)!.error_fetching_product_details);
                            }

                            var productData = productSnapshot.data!.data() as Map<String, dynamic>;
                            String description = productData['description'] ?? AppLocalizations.of(context)!.no_description;
                            double price = (productData['price'] is String
                                ? double.tryParse(productData['price']) ?? 0.0
                                : productData['price']) ??
                                0.0;

                            return ListTile(
                              title: Text(description),
                              subtitle: Text(AppLocalizations.of(context)!.quantity(quantity.toString())),
                              trailing: Text(price.toStringAsFixed(2)),
                            );
                          },
                        );
                      }),
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
