import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  Future<void> _updateOrderStatus(String orderId, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Orders'),
      ),
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
                      Text('Total: \$${order['totalPrice'].toStringAsFixed(2)}'),
                      Text('Status: $orderStatus'),
                    ],
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Text(order['firstName'][0]),
                  ),
                  childrenPadding: const EdgeInsets.all(16.0),
                  children: [
                    ListTile(
                      title: Text('${order['firstName']} ${order['lastName']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${order['email']}'),
                          Text('Phone: ${order['phone']}'),
                          Text('Address: ${order['address']}'),
                        ],
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Products:', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    Column(
                      children: order['products'].entries.map<Widget>((entry) {
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
                                backgroundImage: NetworkImage(productData['imageUrl']),
                                radius: 20.0,
                              ),
                              title: Text(productData['description']),
                              subtitle: Text('Quantity: ${entry.value}'),
                              trailing: Text(
                                '\$${(double.tryParse(productData['price']) ?? 0.0 * entry.value).toStringAsFixed(2)}',
                              ),
                            );

                          },
                        );
                      }).toList(),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // Add logic for additional actions if needed
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Order'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) => _updateOrderStatus(orderId, value),
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
      ),
    );
  }
}
