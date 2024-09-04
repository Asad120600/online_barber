import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart.dart';

class ProductDisplayPage extends StatefulWidget {
  const ProductDisplayPage({super.key});

  @override
  _ProductDisplayPageState createState() => _ProductDisplayPageState();
}

class _ProductDisplayPageState extends State<ProductDisplayPage> {
  final Map<String, int> _productQuantities = {}; // Track product quantities
  final Map<String, double> _productPrices = {}; // Track product prices
  double _totalPrice = 0.0; // Track total price

  void _updateTotalPrice() {
    double total = 0.0;
    _productQuantities.forEach((id, quantity) {
      final price = _productPrices[id] ?? 0.0;
      total += price * quantity;
    });
    setState(() {
      _totalPrice = total;
    });
  }

  void _addToCart() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => CartPage(
        productQuantities: _productQuantities,
        totalPrice: _totalPrice,
      ),
    ));
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),  // Close the preview when tapped
          child: InteractiveViewer(
            child: Image.network(imageUrl, fit: BoxFit.contain),  // Enable pinch to zoom
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
        actions: [
          IconButton(
            onPressed: _addToCart,
            icon: const Icon(Icons.card_travel_sharp),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data?.docs;

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products?.length ?? 0,
            itemBuilder: (context, index) {
              final product = products![index].data() as Map<String, dynamic>;
              final productId = products[index].id;
              final quantity = _productQuantities[productId] ?? 0;
              final price = double.tryParse(product['price']) ?? 0.0;

              if (!_productPrices.containsKey(productId)) {
                _productPrices[productId] = price;
              }

              return GestureDetector(
                onTap: () => _showImagePreview(context, product['imageUrl']),
                child: Card(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: CircleAvatar(
                            radius: 60,  // Adjust the radius as needed
                            backgroundImage: NetworkImage(product['imageUrl']),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Price: ${price.toStringAsFixed(2)}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(product['description']),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              if (quantity > 0) {
                                setState(() {
                                  _productQuantities[productId] = quantity - 1;
                                  _updateTotalPrice();
                                });
                              }
                            },
                          ),
                          Text('$quantity'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _productQuantities[productId] = quantity + 1;
                                _updateTotalPrice();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Visibility(
        visible: _productQuantities.isNotEmpty,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: ${_totalPrice.toStringAsFixed(2)}'),
              ElevatedButton(
                onPressed: _addToCart,
                child: const Text('Add to Cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
