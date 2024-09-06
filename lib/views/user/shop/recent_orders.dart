import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RecentOrdersPage extends StatelessWidget {
  final String userId;

  const RecentOrdersPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId) // Filter orders by userId
            .orderBy('orderDate', descending: true)
            .snapshots(),
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
            padding: const EdgeInsets.all(8.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final orderStatus = order['status'] ?? 'Pending'; // Default to 'Pending' if status is null
              final orderDate = order['orderDate']?.toDate()?.toLocal() ?? DateTime.now(); // Default to now if date is null

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text('Order ID: $orderId'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total: ${order['totalPrice']?.toStringAsFixed(2) ?? '0.00'}'),
                      Text('Status: $orderStatus'),
                    ],
                  ),
                  trailing: Text(
                    '${orderDate.toLocal()}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  childrenPadding: const EdgeInsets.all(16.0),
                  children: [
                    ListTile(
                      title: Text('Delivery Address: ${order['address'] ?? 'N/A'}'),
                      subtitle: Text('Phone: ${order['phone'] ?? 'N/A'}'),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Products:', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ...order['products']?.entries.map<Widget>((entry) {
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            leading: CircleAvatar(
                              backgroundImage: productData['imageUrl'] != null
                                  ? NetworkImage(productData['imageUrl'])
                                  : null,
                              radius: 25,
                              child: productData['imageUrl'] == null
                                  ? const Icon(Icons.image, size: 30, color: Colors.grey)
                                  : null,
                            ),
                            title: Text(productData['description'] ?? 'No description'),
                            subtitle: Text('Quantity: ${entry.value}'),
                            trailing: Text('${(double.tryParse(productData['price']) ?? 0.0 * entry.value).toStringAsFixed(2)}'),
                          );
                        },
                      );
                    })?.toList() ?? [const ListTile(title: Text('No products available'))],
                    const Divider(),
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
