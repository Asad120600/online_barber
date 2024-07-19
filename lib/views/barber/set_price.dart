import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Import Firebase Auth
import '../../models/service_model.dart';

class SetServicePrices extends StatefulWidget {
  const SetServicePrices({super.key, required Service service, required String barberId});

  @override
  _SetServicePricesState createState() => _SetServicePricesState();
}

class _SetServicePricesState extends State<SetServicePrices> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _priceControllers = {};
  late List<Service> _services = [];
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';  // Get current user ID
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('services').get();
      final services = snapshot.docs.map((doc) => Service.fromSnapshot(doc)).toList();

      setState(() {
        _services = services;

        print('Current User ID: $_currentUserId');

        for (var service in services) {
          print('Service ID: ${service.id}');
          print('Service Barber Prices: ${service.barberPrices}');

          // Find the price specific to the current user
          final userPrice = service.barberPrices?.firstWhere(
                  (price) => price['barberId'] == _currentUserId,
              orElse: () => {'price': service.price}
          )['price'];

          print('Selected Price: $userPrice');

          _priceControllers[service.id] = TextEditingController(
            text: (userPrice ?? service.price).toString(),
          );
        }
      });
    } catch (e) {
      print("Error fetching services: $e");
    }
  }

  Future<void> _savePrices() async {
    try {
      for (var service in _services) {
        final newPrice = double.parse(_priceControllers[service.id]!.text);

        final userPrice = {'barberId': _currentUserId, 'price': newPrice};

        final serviceDoc = FirebaseFirestore.instance.collection('services').doc(service.id);
        final serviceSnapshot = await serviceDoc.get();

        if (serviceSnapshot.exists) {
          final data = serviceSnapshot.data() as Map<String, dynamic>;
          final existingPrices = List<Map<String, dynamic>>.from(data['barberPrices'] ?? []);

          // Check if there's already a price entry for the current user
          final index = existingPrices.indexWhere((price) => price['barberId'] == _currentUserId);

          if (index != -1) {
            // Update the existing price entry
            existingPrices[index] = userPrice;
          } else {
            // Add a new price entry
            existingPrices.add(userPrice);
          }

          await serviceDoc.update({'barberPrices': existingPrices});
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prices updated successfully')));
    } catch (e) {
      print("Error saving prices: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating prices')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Service Prices'),
      ),
      body: _services.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ..._services.map((service) {
                return TextFormField(
                  controller: _priceControllers[service.id],
                  decoration: InputDecoration(labelText: '${service.name} Price'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    return null;
                  },
                );
              }).toList(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
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
