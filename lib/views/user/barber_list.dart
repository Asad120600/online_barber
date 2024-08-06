import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:online_barber_app/models/barber_model.dart';
import 'package:online_barber_app/models/service_model.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/user/book_appointment.dart';

class BarberList extends StatefulWidget {
  final List<Service> selectedServices;

  const BarberList({super.key, required this.selectedServices});

  @override
  State<BarberList> createState() => _BarberListState();
}

class _BarberListState extends State<BarberList> {
  List<Service> _selectedServices = [];
  String? _selectedBarberId;
  Barber? _selectedBarber;

  @override
  void initState() {
    super.initState();
    _selectedServices = widget.selectedServices;
  }

  Stream<List<Barber>> getBarbers() {
    return FirebaseFirestore.instance.collection('barbers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Barber.fromSnapshot(doc)).toList();
    });
  }

  Future<Map<String, Map<String, double>>> _getBarberPrices(List<Service> services) async {
    final prices = <String, Map<String, double>>{};

    try {
      for (var service in services) {
        final snapshot = await FirebaseFirestore.instance
            .collection('services')
            .doc(service.id)
            .get();
        final serviceData = Service.fromSnapshot(snapshot);

        final barberPrices = serviceData.barberPrices?.fold<Map<String, double>>({}, (acc, priceMap) {
          final barberId = priceMap['barberId'] as String;
          final price = (priceMap['price'] as num).toDouble();
          if (!acc.containsKey(barberId)) {
            acc[barberId] = price;
          }
          return acc;
        }) ?? {};

        prices[service.id] = barberPrices;
      }
    } catch (e) {
      log('Error fetching barber prices: $e');
      rethrow;
    }

    return prices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Barber'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Barber>>(
              stream: getBarbers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LoadingDots());
                } else if (snapshot.hasError) {
                  log('Error fetching barbers: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No barbers found'));
                } else {
                  return FutureBuilder<Map<String, Map<String, double>>>(
                    future: _getBarberPrices(_selectedServices),
                    builder: (context, priceSnapshot) {
                      if (priceSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: LoadingDots());
                      } else if (priceSnapshot.hasError) {
                        log('Error fetching barber prices: ${priceSnapshot.error}');
                        return Center(child: Text('Error: ${priceSnapshot.error}'));
                      } else if (!priceSnapshot.hasData) {
                        return const Center(child: Text('No pricing data found'));
                      } else {
                        final prices = priceSnapshot.data!;

                        return ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final barber = snapshot.data![index];
                            final barberId = barber.id;

                            final barberPrices = _selectedServices.map((service) {
                              final price = prices[service.id]?[barberId] ?? service.price;
                              return '${service.name}: ${price.toStringAsFixed(2)}';
                            }).join(', ');

                            final isSelected = barberId == _selectedBarberId;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                color: isSelected ? Colors.orange[50] : Colors.white,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16.0),
                                  leading: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.orange,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: barber.imageUrl.isNotEmpty
                                          ? Image.network(
                                        barber.imageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      )
                                          : const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    barber.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Shop: ${barber.shopName}\nAddress: ${barber.address}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        'Prices: $barberPrices',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          RatingBarIndicator(
                                            rating: barber.rating,
                                            itemBuilder: (context, index) => const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                            ),
                                            itemCount: 5,
                                            itemSize: 20.0,
                                            direction: Axis.horizontal,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(barber.rating.toStringAsFixed(1)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedBarberId = barberId;
                                      _selectedBarber = barber;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Button(
              onPressed: _selectedBarberId != null
                  ? () {
                if (_selectedBarber != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookAppointment(
                        selectedServices: _selectedServices,
                        uid: LocalStorage.getUserID().toString(),
                        barberId: _selectedBarber!.id,
                        barberName: _selectedBarber!.name,
                        barberAddress: _selectedBarber!.address,
                      ),
                    ),
                  );
                }
              }
                  : null,
              child: const Text('Confirm'),
            ),
          ),
        ],
      ),
    );
  }
}
