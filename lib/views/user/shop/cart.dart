import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/user/shop/checkout.dart';

class CartPage extends StatelessWidget {
  final Map<String, int> productQuantities;
  final double totalPrice;

  const CartPage({
    super.key,
    required this.productQuantities,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Filter the productQuantities map to show only products with quantity > 0
    final cartItems = productQuantities.entries.where((entry) => entry.value > 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.cartTitle),
      ),
      body: ListView.builder(
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          final productId = cartItems[index].key;
          final quantity = cartItems[index].value;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListTile(
                  title: Text(localizations.loadingText),
                );
              }

              if (snapshot.hasError) {
                return ListTile(
                  title: Text(localizations.errorLabel(snapshot.error.toString())),
                );
              }

              final productData = snapshot.data?.data() as Map<String, dynamic>?;

              if (productData == null) {
                return ListTile(
                  title: Text(localizations.productNotFound),
                );
              }

              final price = (double.tryParse(productData['price']) ?? 0.0) * quantity;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(productData['imageUrl']),
                ),
                title: Text(productData['description']),
                subtitle: Text(localizations.quantityLabel(quantity.toString())),
                trailing: Text(price.toStringAsFixed(2)),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8.0),
        color: Colors.grey[200],
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Adjust the font size based on the available width
            double fontSize = constraints.maxWidth > 200 ? 16 : 14; // Adjust font size as needed

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(localizations.totalPriceLabel(totalPrice.toStringAsFixed(2))),
                SizedBox(
                  width: 118, // Ensure this width fits the button content without wrapping
                  child: Button(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => CheckoutPage(
                          productQuantities: productQuantities,
                          totalPrice: totalPrice,
                          userId: LocalStorage().getCurrentUserId().toString(),
                        ),
                      ));
                    },
                    child: Text(
                      localizations.checkoutButton,
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
