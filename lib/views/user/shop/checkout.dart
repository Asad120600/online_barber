import 'dart:developer';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:online_barber_app/push_notification_service.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/user/shop/recent_orders.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, int> productQuantities;
  final double totalPrice;
  final String userId;

  const CheckoutPage({
    super.key,
    required this.productQuantities,
    required this.totalPrice,
    required this.userId,
  });

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false; // New state variable to manage loading indicator

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        _emailController.text = userData['email'] ?? '';
        _firstNameController.text = userData['firstName'] ?? '';
        _lastNameController.text = userData['lastName'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _addressController.text = userData['address'] ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user details: ${e.toString()}')),
      );
    }
  }

  Future<String> _getProductNames() async {
    List<String> productNames = [];
    for (var entry in widget.productQuantities.entries) {
      final productId = entry.key;
      final snapshot = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      if (snapshot.exists) {
        var productData = snapshot.data() as Map<String, dynamic>;
        productNames.add(productData['description'] ?? 'Unknown Product');
      }
    }
    return productNames.join(', ');
  }

  Future<void> _sendNotificationToAdmin(String uid, String orderId) async {
    try {
      // Fetch the admin document based on uid
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();

      if (adminDoc.exists) {
        var adminData = adminDoc.data() as Map<String, dynamic>;
        String adminToken = adminData['token'];

        // Fetch product names
        String productNames = await _getProductNames();

        // Construct the notification message
        String message = 'An order with ID $orderId has been placed. Products: $productNames. Please check the admin panel for details.';

        log('Sending notification to admin with token: $adminToken'); // Debug log

        // Send notification to admin using PushNotificationService
        await PushNotificationService.sendNotification(
          adminToken,
          context,
          'New Order Received',
          message,
        );
      } else {
        log(AppLocalizations.of(context)!.adminDocNotFound);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.adminDocNotFound)),
        );
      }
    } catch (e) {
      log('AppLocalizations.of(context)!.sendingNotificationError : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AppLocalizations.of(context)!.sendingNotificationError ${e.toString()}')),
      );
    }
  }

  Future<void> _confirmOrder() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      try {
        // Retrieve the current user ID and device token
        String currentUserId = LocalStorage().getCurrentUserId();
        String? deviceToken = LocalStorage().getFirebaseToken(); // deviceToken is nullable

        if (deviceToken == null) {
          // Handle the case where deviceToken is null
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.deviceTokenError)),
          );
          setState(() {
            _isLoading = false; // Hide loading indicator
          });
          return;
        }

        // Store the order in Firestore
        DocumentReference orderRef = await FirebaseFirestore.instance.collection('orders').add({
          'userId': widget.userId,
          'email': _emailController.text,
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'products': widget.productQuantities,
          'totalPrice': widget.totalPrice,
          'orderDate': Timestamp.now(),
          'uid': currentUserId, // Store the current user ID
          'deviceToken': deviceToken, // Store the device token
        });

        // Send notification to the admin (example uid used here)
        await _sendNotificationToAdmin('NF0CnhZ0nBZY3fOB7l0zUvio5Zk1', orderRef.id);

        // Empty the cart
        await FirebaseFirestore.instance.collection('carts').doc(widget.userId).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );

        // Navigate to RecentOrdersPage after successful order placement
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RecentOrdersPage(
              userId: LocalStorage().getCurrentUserId(),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final cartItems = widget.productQuantities.entries.where((entry) => entry.value > 0).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.checkoutTitle),
      ),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.orderSummary,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final productId = cartItems[index].key;
                    final quantity = cartItems[index].value;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return ListTile(
                            title: Text(localizations.productNotFound),
                          );
                        }

                        var productData = snapshot.data!.data() as Map<String, dynamic>;

                        return ListTile(
                          title: Text(productData['description'] ?? localizations.noDescription),
                          subtitle: Text('Quantity: $quantity'),
                          trailing: Text('\$${(productData['price'] ?? 0) * quantity}'),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Total Price: \$${widget.totalPrice}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: localizations.emailLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0), // Circular border
                          ),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? localizations.emailValidation : null,
                      ),
                      const SizedBox(height: 16), // Spacing between fields
                      TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          labelText: localizations.firstNameLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0), // Circular border
                          ),
                        ),
                        validator: (value) => value?.isEmpty ?? true ?localizations.firstNameValidation : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: localizations.lastNameLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0), // Circular border
                          ),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? localizations.lastNameValidation : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: localizations.phoneLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0), // Circular border
                          ),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? localizations.phoneValidation: null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: localizations.address,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0), // Circular border
                          ),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? localizations.addressValidation : null,
                      ),

                      const SizedBox(height: 16),
                      Button(
                        onPressed: _confirmOrder,
                         child: Text(localizations.confirmOrderButton),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) ...[
            Container(
              color: Colors.black54,
              child: const Center(child: LoadingDots()), // Show LoadingDots when loading
            ),
          ],
        ],
      ),
    );
  }
}
