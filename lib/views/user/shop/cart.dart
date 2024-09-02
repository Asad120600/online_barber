import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  final Map<String, int> productQuantities;
  final double totalPrice;

  CartPage({
    required this.productQuantities,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cart')),
      body: ListView.builder(
        itemCount: productQuantities.length,
        itemBuilder: (context, index) {
          final productId = productQuantities.keys.elementAt(index);
          final quantity = productQuantities[productId]!;
          // You may need to fetch product details from Firestore again here
          // For simplicity, assuming product details are available
          return ListTile(
            title: Text('Product ID: $productId'),
            subtitle: Text('Quantity: $quantity'),

          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8.0),
        color: Colors.grey[200],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total: \$${totalPrice.toStringAsFixed(2)}'),
            ElevatedButton(
              onPressed: () {
                // Navigate to checkout page
              },
              child: Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
