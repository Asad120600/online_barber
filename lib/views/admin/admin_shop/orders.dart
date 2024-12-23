import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:online_barber_app/push_notification_service.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  Future<void> _updateOrderStatus(BuildContext context, String orderId, String status, String? token, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': status});

      String message = '';
      String notificationBody = '';

      if (status == 'Confirmed') {
        message = AppLocalizations.of(context)!.orderConfirmed;
        notificationBody = AppLocalizations.of(context)!.orderConfirmedBody(orderId);
      } else if (status == 'Shipped') {
        message = AppLocalizations.of(context)!.orderShipped;
        notificationBody = AppLocalizations.of(context)!.orderShippedBody(orderId);
      } else if (status == 'Delivered') {
        message = AppLocalizations.of(context)!.orderDelivered;
        notificationBody = AppLocalizations.of(context)!.orderDeliveredBody(orderId);
      }

      if (message.isNotEmpty && notificationBody.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'orderId': orderId,
          'userId': userId,
          'message': message,
          'body': notificationBody,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (token != null && token.isNotEmpty) {
        await PushNotificationService.sendNotificationToUser(token, context, message, notificationBody);
      } else {
        print(AppLocalizations.of(context)!.invalidToken);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedToUpdateOrder(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.adminOrders),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('orderDate', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.errorr(snapshot.error.toString())));
          }

          final orders = snapshot.data?.docs;

          if (orders == null || orders.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noRecentOrders));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final orderStatus = order['status'] ?? 'Pending';
              final userToken = order['deviceToken'] as String?;
              final userId = order['userId'] ?? '';

              return Card(
                elevation: 4.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ExpansionTile(
                  title: Text(
                    AppLocalizations.of(context)!.orderId(orderId),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.totalPriceLabel(
                        (order['totalPrice'] != null ? double.tryParse(order['totalPrice'].toString())?.toStringAsFixed(2) : '0.00') ?? '0.00',
                      )),
                      Text(AppLocalizations.of(context)!.status(orderStatus)),
                    ],
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Text(order['firstName']?.isNotEmpty ?? false ? order['firstName']![0] : '?'),
                  ),
                  childrenPadding: const EdgeInsets.all(16.0),
                  children: [
                    ListTile(
                      title: Text('${order['firstName']} ${order['lastName']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.email_e(order['email'] ?? 'N/A')),
                          Text(AppLocalizations.of(context)!.phone(order['phone'] ?? 'N/A')),
                          Text(AppLocalizations.of(context)!.address_e(order['address'] ?? 'N/A')),
                        ],
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(AppLocalizations.of(context)!.products, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    Column(
                      children: order['products']?.entries.map<Widget>((entry) {
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('products').doc(entry.key).get(),
                          builder: (context, productSnapshot) {
                            if (productSnapshot.connectionState == ConnectionState.waiting) {
                              return ListTile(
                                title: Text(AppLocalizations.of(context)!.loadingProduct),
                              );
                            }

                            if (productSnapshot.hasError) {
                              return ListTile(
                                title: Text(AppLocalizations.of(context)!.errorr(productSnapshot.error.toString())),
                              );
                            }

                            final productData = productSnapshot.data?.data() as Map<String, dynamic>?;

                            if (productData == null) {
                              return ListTile(
                                title: Text(AppLocalizations.of(context)!.productNotFound),
                              );
                            }

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(productData['imageUrl'] ?? ''),
                                radius: 20.0,
                              ),
                              title: Text(productData['description'] ?? AppLocalizations.of(context)!.noDescription),
                              subtitle: Text(AppLocalizations.of(context)!.quantity(entry.value.toString())),
                              trailing: Text(
                                (double.tryParse(productData['price'] ?? '0') ?? 0.0 * entry.value).toStringAsFixed(2),
                              ),
                            );
                          },
                        );
                      })?.toList() ?? [],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 240),
                        PopupMenuButton<String>(
                          onSelected: (value) => _updateOrderStatus(context, orderId, value, userToken, userId),
                          itemBuilder: (BuildContext context) {
                            List<String> statusOptions = [];
                            if (orderStatus == AppLocalizations.of(context)!.pending) {
                              statusOptions = [AppLocalizations.of(context)!.confirmed];
                              statusOptions = [AppLocalizations.of(context)!.confirmed];
                            } else if (orderStatus == AppLocalizations.of(context)!.confirmed) {
                              statusOptions = [AppLocalizations.of(context)!.shipped];
                            } else if (orderStatus == AppLocalizations.of(context)!.shipped) {
                              statusOptions = [AppLocalizations.of(context)!.delivered];
                            }

                            return statusOptions.map((String choice) {
                              return PopupMenuItem<String>(
                                value: choice,
                                child: Text(choice),
                              );
                            }).toList();
                          },
                          icon: const Icon(Icons.more_vert, color: Colors.black),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
