import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:online_barber_app/utils/alert_dialog.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:online_barber_app/utils/loading_dialog.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/barber/barber_panel.dart';
import '../../models/service_model.dart';

class SetServicePrices extends StatefulWidget {
  final String barberId;

  const SetServicePrices({super.key, required this.barberId, required Service service});

  @override
  _SetServicePricesState createState() => _SetServicePricesState();
}

class _SetServicePricesState extends State<SetServicePrices> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _priceControllers = {};
  final TextEditingController _homeServicePriceController = TextEditingController();
  late List<Service> _services = [];
  late String _currentUserId;
  bool _isLoading = false; // Add a loading state variable

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? ''; // Get current user ID
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('services').get();
      final services = snapshot.docs.map((doc) => Service.fromSnapshot(doc)).toList();

      setState(() {
        _services = services;

        log('Current User ID: $_currentUserId');
        log('Fetching prices for Barber ID: ${LocalStorage.getBarberId()}');

        // Initialize the price controllers for each service
        for (var service in services) {
          log('Service ID: ${service.id}');
          log('Service Barber Prices: ${service.barberPrices}');

          final userPrice = service.barberPrices?.firstWhere(
                  (price) => price['barberId'] == LocalStorage.getBarberId(),
              orElse: () => {'price': service.price}
          )['price'];

          // Set the price controller for each service
          _priceControllers[service.id] = TextEditingController(
            text: (userPrice ?? service.price).toString(),
          );
        }

        // Fetch and set the current home service price if available
        final homeServicePrice = services
            .expand((service) => service.barberPrices ?? [])
            .firstWhere(
                (price) => price['barberId'] == LocalStorage.getBarberId() && price['isHomeService'] == true,
            orElse: () => {'price': 0.0}
        )['price'];

        _homeServicePriceController.text = (homeServicePrice ?? 0.0).toString();
      });
    } catch (e) {
      log("Error fetching services: $e");
    }
  }

  Future<void> _showCustomAlertDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: 'Success',
          content: 'Prices have been updated successfully!',
          confirmButtonText: 'OK',
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BarberPanel(barberId: _currentUserId)));
          },
        );
      },
    );
  }

  Future<void> _showLoadingDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return const LoadingDialog(message: "Prices Are Updating");
      },
    );
  }

  Future<void> _savePrices() async {
    _showLoadingDialog(); // Show loading dialog

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final newHomeServicePrice = double.parse(_homeServicePriceController.text);
      final barberId = LocalStorage.getBarberId() ?? ''; // Ensure barberId is not null

      for (var service in _services) {
        final newPrice = double.parse(_priceControllers[service.id]!.text);

        final userPrice = {'barberId': barberId, 'price': newPrice};
        final userHomeServicePrice = {'barberId': barberId, 'price': newHomeServicePrice, 'isHomeService': true};

        final serviceDoc = FirebaseFirestore.instance.collection('services').doc(service.id);
        final serviceSnapshot = await serviceDoc.get();

        if (serviceSnapshot.exists) {
          final data = serviceSnapshot.data() as Map<String, dynamic>;
          final existingPrices = List<Map<String, dynamic>>.from(data['barberPrices'] ?? []);

          // Update or add the price entry for the service
          final index = existingPrices.indexWhere(
                  (price) => price['barberId'] == barberId && (price['isHomeService'] == false || price['isHomeService'] == null)
          );

          if (index != -1) {
            existingPrices[index] = userPrice;
          } else {
            existingPrices.add(userPrice);
          }

          // Update or add home service price entry
          final homeServiceIndex = existingPrices.indexWhere(
                  (price) => price['barberId'] == barberId && price['isHomeService'] == true
          );

          if (homeServiceIndex != -1) {
            existingPrices[homeServiceIndex] = userHomeServicePrice;
          } else {
            existingPrices.add(userHomeServicePrice);
          }

          // Update Firestore with the modified prices
          await serviceDoc.update({'barberPrices': existingPrices});

          log('Updated prices for service ${service.id}: $existingPrices');
        }
      }

    } catch (e) {
      log("Error saving prices: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating prices')));
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });

      Navigator.of(context).pop(); // Close loading dialog

      // Show the custom alert dialog after loading is complete
      await _showCustomAlertDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Service Prices'),
      ),
      body: _isLoading
          ? const Center(child: LoadingDots()) // Loading dots while prices are updating
          : _services.isEmpty
          ? const Center(child: LoadingDots())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ..._services.map((service) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _priceControllers[service.id],
                      decoration: InputDecoration(labelText: '${service.name} Price'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        return null;
                      },
                    ),
                  ],
                );
              }).toList(),
              TextFormField(
                controller: _homeServicePriceController,
                decoration: const InputDecoration(labelText: 'Home Service Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a home service price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Button(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _savePrices();
                    }
                  },
                  child: const Text('Save Prices'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
