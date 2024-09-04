import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:online_barber_app/push_notification_service.dart';
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
        log('Admin document not found');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin document not found')),
        );
      }
    } catch (e) {
      log('Error sending notification to admin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending notification: ${e.toString()}')),
      );
    }
  }

  Future<void> _confirmOrder() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
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
        });

        // Send notification to the admin (example uid used here)
        await _sendNotificationToAdmin('OEQj3lxQnPcdcyeuJEIsm9MxDWx1', orderRef.id);

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
              userId: LocalStorage().getCurrentUserId().toString(),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = widget.productQuantities.entries.where((entry) => entry.value > 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
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
                      return const ListTile(
                        title: Text('Loading...'),
                      );
                    }

                    if (snapshot.hasError) {
                      return ListTile(
                        title: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final productData = snapshot.data?.data() as Map<String, dynamic>?;

                    if (productData == null) {
                      return const ListTile(
                        title: Text('Product not found'),
                      );
                    }

                    final price = double.tryParse(productData['price']) ?? 0.0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(productData['imageUrl']),
                      ),
                      title: Text(productData['description']),
                      subtitle: Text('Quantity: $quantity'),
                      trailing: Text((price * quantity).toStringAsFixed(2)),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Details', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${widget.totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton(
                  onPressed: _confirmOrder,
                  child: const Text('Confirm Order'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
