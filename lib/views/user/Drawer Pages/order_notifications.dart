import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:online_barber_app/models/order_notification_model.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/user/shop/recent_orders.dart';

class OrderNotificationsTab extends StatelessWidget {
  final String uid;  // User ID passed in constructor

  const OrderNotificationsTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderNotificationModel>>(
      stream: _getOrderNotificationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingDots());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No order notifications found.'));
        } else {
          List<OrderNotificationModel> notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              OrderNotificationModel notification = notifications[index];

              // Fetch the product names using the orderId
              return FutureBuilder<Map<String, String>>(
                future: _getProductNames(notification.orderId),  // Fetch product names
                builder: (context, productSnapshot) {
                  if (productSnapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingDots();
                  } else if (productSnapshot.hasError) {
                    return Text('Error fetching products: ${productSnapshot.error}');
                  } else {
                    Map<String, String> productNames = productSnapshot.data ?? {};

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          notification.message,  // Notification message
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification.body),
                            const SizedBox(height: 4),
                            ...productNames.entries.map((entry) =>
                                Text('Product: ${entry.value} (Quantity: ${entry.key})') // Display each product name with quantity
                            ),
                          ],
                        ),
                        trailing: Text(DateFormat('dd/MM/yyyy').format(notification.timestamp)),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RecentOrdersPage(userId: LocalStorage().getCurrentUserId())));
                        },
                      ),
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }

  // Stream to get only the current user's order notifications
  Stream<List<OrderNotificationModel>> _getOrderNotificationsStream() {
    return FirebaseFirestore.instance
        .collection('notifications')  // Query from 'notifications' collection
        .where('userId', isEqualTo: uid)  // Filter by current user's ID
        .where('message', isEqualTo: 'Order Confirmed')  // Filter by 'order' notifications
        .snapshots()
        .asyncMap((notificationSnapshot) async {
      // Convert Firestore documents to OrderNotificationModel
      List<OrderNotificationModel> notifications = notificationSnapshot.docs
          .map((doc) => OrderNotificationModel.fromFirestore(doc))  // Updated to use OrderNotificationModel
          .toList();

      // Sort notifications by date
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return notifications;
    });
  }

  // Function to fetch product names based on orderId
  Future<Map<String, String>> _getProductNames(String orderId) async {
    try {
      DocumentSnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (orderSnapshot.exists) {
        Map<String, dynamic>? orderData = orderSnapshot.data() as Map<String, dynamic>?;

        // Fetch the products field which is a Map
        Map<String, dynamic>? products = orderData?['products'];

        Map<String, String> productNames = {};
        if (products != null) {
          // Iterate through each product ID in the products map
          for (var productId in products.keys) {
            // Fetch product details from products collection
            String? productName = await _getProductNameById(productId);
            if (productName != null) {
              productNames[products[productId].toString()] = productName;  // Store quantity and product name
            }
          }
        }
        return productNames;  // Return the map of product names
      }
    } catch (e) {
      print('Error fetching product names: $e');
    }
    return {};
  }

  // Function to fetch a single product name from the products collection based on product ID
  Future<String?> _getProductNameById(String productId) async {
    try {
      DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (productSnapshot.exists) {
        Map<String, dynamic>? productData = productSnapshot.data() as Map<String, dynamic>?;
        return productData?['name'];  // Assuming the product name is stored in 'name' field
      }
    } catch (e) {
      print('Error fetching product name: $e');
    }
    return null;
  }
}


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:online_barber_app/models/order_notification_model.dart';
// import 'package:online_barber_app/utils/shared_pref.dart';
// import 'package:online_barber_app/views/user/shop/recent_orders.dart'; // Updated to OrderNotificationModel
//
// class OrderNotificationsTab extends StatelessWidget {
//   final String uid;  // User ID passed in constructor
//
//   const OrderNotificationsTab({super.key, required this.uid});
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<List<OrderNotificationModel>>(
//       stream: _getOrderNotificationsStream(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Center(child: Text('No order notifications found.'));
//         } else {
//           List<OrderNotificationModel> notifications = snapshot.data!;
//
//           return ListView.builder(
//             itemCount: notifications.length,
//             itemBuilder: (context, index) {
//               OrderNotificationModel notification = notifications[index];
//               return Card(
//                 margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(16),
//                   title: Text(
//                     notification.message,  // Updated to match field in Firestore
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(notification.body),
//                       const SizedBox(height: 4),
//                     ],
//                   ),
//                   trailing: Text(DateFormat('dd/MM/yyyy').format(notification.timestamp)),
//                   onTap: () {
//                     Navigator.push(context, MaterialPageRoute(builder: (context)=>RecentOrdersPage(userId: LocalStorage().getCurrentUserId())));
//                   },
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
//   Stream<List<OrderNotificationModel>> _getOrderNotificationsStream() {
//     return FirebaseFirestore.instance
//         .collection('notifications')  // Query from 'notifications' collection
//         .where('userId', isEqualTo: uid)  // Filter by current user's ID
//         .where('message', isEqualTo: 'Order Confirmed')  // Filter by 'order' notifications
//         .snapshots()
//         .asyncMap((notificationSnapshot) async {
//       // Convert Firestore documents to OrderNotificationModel
//       List<OrderNotificationModel> notifications = notificationSnapshot.docs
//           .map((doc) => OrderNotificationModel.fromFirestore(doc))  // Updated to use OrderNotificationModel
//           .toList();
//
//       // Sort notifications by date
//       notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
//
//       return notifications;
//     });
//   }
// }
