import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CheckoutPage extends StatelessWidget {
  final Map<String, int> productQuantities;

  const CheckoutPage({super.key, required this.productQuantities});

  @override
  Widget build(BuildContext context) {
    double totalPrice = 0.0;

    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: FutureBuilder(
        future: Future.wait(
          productQuantities.keys.map((id) =>
              FirebaseFirestore.instance.collection('products').doc(id).get()),
        ),
        builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data;
          if (products == null || products.isEmpty) {
            return Center(child: Text('No products found'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index].data() as Map<String, dynamic>;
                    final productId = products[index].id;
                    final quantity = productQuantities[productId] ?? 1;
                    final price = double.tryParse(product['price']) ?? 0.0;
                    totalPrice += price * quantity;

                    return ListTile(
                      leading: Image.network(product['imageUrl'], width: 50, height: 50, fit: BoxFit.cover),
                      title: Text('Price: ${product['price']}'),
                      subtitle: Text('Quantity: $quantity'),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Total Price: \$${totalPrice.toStringAsFixed(2)}'),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Handle checkout process here
                  },
                  child: Text('Complete Purchase'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
