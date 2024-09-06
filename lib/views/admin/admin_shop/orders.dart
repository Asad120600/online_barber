import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:online_barber_app/push_notification_service.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  Future<void> _updateOrderStatus(BuildContext context, String orderId, String status, String? token) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': status});

      String message = '';
      String notificationBody = '';

      if (status == 'Confirmed') {
        message = 'Order Confirmed';
        notificationBody = 'Your order $orderId has been confirmed.';
      } else if (status == 'Shipped') {
        message = 'Order Shipped';
        notificationBody = 'Your order $orderId has been shipped.';
      } else if (status == 'Delivered') {
        message = 'Order Delivered';
        notificationBody = 'Your order $orderId has been delivered.';
      }

      // Create notification document in Firestore
      if (message.isNotEmpty && notificationBody.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'orderId': orderId,
          'message': message,
          'body': notificationBody,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Send notification to user via FCM
      if (token != null && token.isNotEmpty) {
        await PushNotificationService.sendNotificationToUser(token, context, message, notificationBody);
      } else {
        print('Invalid token or message');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Orders'),
      ),
      // body: StreamBuilder<QuerySnapshot>(
      //   stream: FirebaseFirestore.instance.collection('orders').orderBy('orderDate', descending: true).snapshots(),
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Center(child: CircularProgressIndicator());
      //     }
      //
      //     if (snapshot.hasError) {
      //       return Center(child: Text('Error: ${snapshot.error}'));
      //     }
      //
      //     final orders = snapshot.data?.docs;
      //
      //     if (orders == null || orders.isEmpty) {
      //       return const Center(child: Text('No recent orders'));
      //     }
      //
      //     return ListView.builder(
      //       padding: const EdgeInsets.all(16.0),
      //       itemCount: orders.length,
      //       itemBuilder: (context, index) {
      //         final order = orders[index].data() as Map<String, dynamic>;
      //         final orderId = orders[index].id;
      //         final orderStatus = order['status'] ?? 'Pending'; // Default to 'Pending' if status is null
      //         final userToken = order['deviceToken'] as String?; // Ensure this is handled as a nullable String
      //
      //         return Card(
      //           elevation: 4.0,
      //           margin: const EdgeInsets.symmetric(vertical: 8.0),
      //           shape: RoundedRectangleBorder(
      //             borderRadius: BorderRadius.circular(10.0),
      //           ),
      //           child: ExpansionTile(
      //             title: Text(
      //               'Order ID: $orderId',
      //               style: const TextStyle(fontWeight: FontWeight.bold),
      //             ),
      //             subtitle: Column(
      //               crossAxisAlignment: CrossAxisAlignment.start,
      //               children: [
      //                 Text('Total: ${order['totalPrice']?.toStringAsFixed(2) ?? '0.00'}'),
      //                 Text('Status: $orderStatus'),
      //               ],
      //             ),
      //             leading: CircleAvatar(
      //               backgroundColor: Colors.orangeAccent,
      //               child: Text(order['firstName']?.isNotEmpty ?? false ? order['firstName']![0] : '?'),
      //             ),
      //             childrenPadding: const EdgeInsets.all(16.0),
      //             children: [
      //               ListTile(
      //                 title: Text('${order['firstName']} ${order['lastName']}'),
      //                 subtitle: Column(
      //                   crossAxisAlignment: CrossAxisAlignment.start,
      //                   children: [
      //                     Text('Email: ${order['email'] ?? 'N/A'}'),
      //                     Text('Phone: ${order['phone'] ?? 'N/A'}'),
      //                     Text('Address: ${order['address'] ?? 'N/A'}'),
      //                   ],
      //                 ),
      //               ),
      //               const Divider(),
      //               Padding(
      //                 padding: const EdgeInsets.symmetric(vertical: 8.0),
      //                 child: Text('Products:', style: Theme.of(context).textTheme.titleMedium),
      //               ),
      //               Column(
      //                 children: order['products']?.entries.map<Widget>((entry) {
      //                   return FutureBuilder<DocumentSnapshot>(
      //                     future: FirebaseFirestore.instance.collection('products').doc(entry.key).get(),
      //                     builder: (context, productSnapshot) {
      //                       if (productSnapshot.connectionState == ConnectionState.waiting) {
      //                         return const ListTile(
      //                           title: Text('Loading product...'),
      //                         );
      //                       }
      //
      //                       if (productSnapshot.hasError) {
      //                         return ListTile(
      //                           title: Text('Error: ${productSnapshot.error}'),
      //                         );
      //                       }
      //
      //                       final productData = productSnapshot.data?.data() as Map<String, dynamic>?;
      //
      //                       if (productData == null) {
      //                         return const ListTile(
      //                           title: Text('Product not found'),
      //                         );
      //                       }
      //
      //                       return ListTile(
      //                         leading: CircleAvatar(
      //                           backgroundImage: NetworkImage(productData['imageUrl'] ?? ''),
      //                           radius: 20.0,
      //                         ),
      //                         title: Text(productData['description'] ?? 'No Description'),
      //                         subtitle: Text('Quantity: ${entry.value}'),
      //                         trailing: Text(
      //                           '${(double.tryParse(productData['price'] ?? '0') ?? 0.0 * entry.value).toStringAsFixed(2)}',
      //                         ),
      //                       );
      //                     },
      //                   );
      //                 })?.toList() ?? [],
      //               ),
      //               const Divider(),
      //               Row(
      //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //                 children: [
      //                  const SizedBox(width: 250,),
      //                   PopupMenuButton<String>(
      //                     onSelected: (value) => _updateOrderStatus(context, orderId, value, userToken),
      //                     itemBuilder: (BuildContext context) {
      //                       // Determine the next possible statuses based on the current status
      //                       List<String> statusOptions = [];
      //                       if (orderStatus == 'Pending') {
      //                         statusOptions = ['Confirmed'];
      //                       } else if (orderStatus == 'Confirmed') {
      //                         statusOptions = ['Shipped'];
      //                       } else if (orderStatus == 'Shipped') {
      //                         statusOptions = ['Delivered'];
      //                       }
      //
      //                       return statusOptions.map((String choice) {
      //                         return PopupMenuItem<String>(
      //                           value: choice,
      //                           child: Text(choice),
      //                         );
      //                       }).toList();
      //                     },
      //                     icon: const Icon(Icons.more_vert, color: Colors.black),
      //                     shape: RoundedRectangleBorder(
      //                       borderRadius: BorderRadius.circular(10.0),
      //                     ),
      //                   ),
      //                 ],
      //               ),
      //             ],
      //           ),
      //         );
      //       },
      //     );
      //   },
      // ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').orderBy('orderDate', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final orders = snapshot.data?.docs;

            if (orders == null || orders.isEmpty) {
              return const Center(child: Text('No recent orders'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index].data() as Map<String, dynamic>;
                final orderId = orders[index].id;
                final orderStatus = order['status'] ?? 'Pending'; // Default to 'Pending' if status is null
                final userToken = order['deviceToken'] as String?; // Ensure this is handled as a nullable String

                return Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Order ID: $orderId',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total: ${order['totalPrice']?.toStringAsFixed(2) ?? '0.00'}'),
                        Text('Status: $orderStatus'),
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
                            Text('Email: ${order['email'] ?? 'N/A'}'),
                            Text('Phone: ${order['phone'] ?? 'N/A'}'),
                            Text('Address: ${order['address'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Products:', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Column(
                        children: order['products']?.entries.map<Widget>((entry) {
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('products').doc(entry.key).get(),
                            builder: (context, productSnapshot) {
                              if (productSnapshot.connectionState == ConnectionState.waiting) {
                                return const ListTile(
                                  title: Text('Loading product...'),
                                );
                              }

                              if (productSnapshot.hasError) {
                                return ListTile(
                                  title: Text('Error: ${productSnapshot.error}'),
                                );
                              }

                              final productData = productSnapshot.data?.data() as Map<String, dynamic>?;

                              if (productData == null) {
                                return const ListTile(
                                  title: Text('Product not found'),
                                );
                              }

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(productData['imageUrl'] ?? ''),
                                  radius: 20.0,
                                ),
                                title: Text(productData['description'] ?? 'No Description'),
                                subtitle: Text('Quantity: ${entry.value}'),
                                trailing: Text(
                                  '${(double.tryParse(productData['price'] ?? '0') ?? 0.0 * entry.value).toStringAsFixed(2)}',
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
                          const SizedBox(width: 250,),
                          PopupMenuButton<String>(
                            onSelected: (value) => _updateOrderStatus(context, orderId, value, userToken),
                            itemBuilder: (BuildContext context) {
                              // Determine the next possible statuses based on the current status
                              List<String> statusOptions = [];
                              if (orderStatus == 'Pending') {
                                statusOptions = ['Confirmed'];
                              } else if (orderStatus == 'Confirmed') {
                                statusOptions = ['Shipped'];
                              } else if (orderStatus == 'Shipped') {
                                statusOptions = ['Delivered'];
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
        )

    );
  }
}
