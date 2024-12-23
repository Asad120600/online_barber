import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:online_barber_app/utils/button.dart';
import 'cart.dart';

class ProductDisplayPage extends StatefulWidget {
  const ProductDisplayPage({super.key});

  @override
  _ProductDisplayPageState createState() => _ProductDisplayPageState();
}

class _ProductDisplayPageState extends State<ProductDisplayPage> {
  final Map<String, int> _productQuantities = {};
  final Map<String, double> _productPrices = {};
  double _totalPrice = 0.0;

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)!.addProductToCart),
    ));
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
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.productListTitle),
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
            return Center(
                child: Text(localizations.errorLabel(snapshot.error.toString())));
          }

          final products = snapshot.data?.docs;

          if (products == null || products.isEmpty) {
            return Center(
              child: Text(localizations.noProductsAvailable),
            );
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;
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
                            radius: 80,
                            backgroundImage: NetworkImage(product['imageUrl']),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(localizations.priceLabel(price)),
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
                          Text(localizations.quantityLabel(quantity.toString())),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              double fontSize = constraints.maxWidth * 0.04;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.totalPriceLabel(_totalPrice.toStringAsFixed(2)),
                    style: TextStyle(fontSize: fontSize),
                  ),
                  SizedBox(
                    width: 106,
                    child: Button(
                      onPressed: _addToCart,
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Text(
                          localizations.addToCart,
                          style: TextStyle(fontSize: fontSize),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
