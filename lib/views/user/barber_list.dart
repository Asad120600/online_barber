import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:online_barber_app/models/barber_model.dart';
import 'package:online_barber_app/models/service_model.dart';
import 'package:online_barber_app/utils/button.dart';
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
  Position? _currentPosition;
  double _maxDistance = 10.0; // Default distance
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedServices = widget.selectedServices;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    // Get the current location
    _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {});
  }

  Future<List<Location>> _getLatLongFromAddress(String address) async {
    try {
      return await locationFromAddress(address);
    } catch (e) {
      log('Error getting location from address: $e');
      return [];
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1000; // in kilometers
  }

  Stream<List<Barber>> getBarbers() {
    return FirebaseFirestore.instance
        .collection('barbers')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Barber.fromSnapshot(doc)).toList();
    });
  }

  Future<Map<String, Map<String, double>>> _getBarberPrices(
      List<Service> services) async {
    final prices = <String, Map<String, double>>{};

    try {
      for (var service in services) {
        final snapshot = await FirebaseFirestore.instance
            .collection('services')
            .doc(service.id)
            .get();
        final serviceData = Service.fromSnapshot(snapshot);

        final barberPrices = serviceData.barberPrices
                ?.fold<Map<String, double>>({}, (acc, priceMap) {
              final barberId = priceMap['barberId'] as String;
              final price = (priceMap['price'] as num).toDouble();
              if (!acc.containsKey(barberId)) {
                acc[barberId] = price;
              }
              return acc;
            }) ??
            {};

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
      body: _currentPosition == null
          ? const Center(
              child: Text(
                  'Loading...')) // Removed LoadingDots, just show a simple text
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Max Distance: ${_maxDistance.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Slider(
                        value: _maxDistance,
                        min: 1.0,
                        max: 50.0,
                        divisions: 49,
                        label: '${_maxDistance.toStringAsFixed(1)} km',
                        onChanged: (value) {
                          setState(() {
                            _maxDistance = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Barber>>(
                    stream: getBarbers(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        log('Error fetching barbers: ${snapshot.error}');
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No barbers found'));
                      } else {
                        return FutureBuilder<Map<String, Map<String, double>>>(
                          future: _getBarberPrices(_selectedServices),
                          builder: (context, priceSnapshot) {
                            if (priceSnapshot.hasError) {
                              log('Error fetching barber prices: ${priceSnapshot.error}');
                              return Center(
                                  child: Text('Error: ${priceSnapshot.error}'));
                            } else if (!priceSnapshot.hasData) {
                              return const Center(
                                  child: Text('No pricing data found'));
                            } else {
                              final prices = priceSnapshot.data!;

                              return ListView.builder(
                                padding: const EdgeInsets.all(8.0),
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  final barber = snapshot.data![index];
                                  return FutureBuilder<List<Location>>(
                                    future:
                                        _getLatLongFromAddress(barber.address),
                                    builder: (context, locationSnapshot) {
                                      if (!locationSnapshot.hasData ||
                                          locationSnapshot.data!.isEmpty) {
                                        return Container(); // Skip if no location data
                                      }

                                      final barberLocation =
                                          locationSnapshot.data!.first;
                                      final distance = _calculateDistance(
                                        _currentPosition!.latitude,
                                        _currentPosition!.longitude,
                                        barberLocation.latitude,
                                        barberLocation.longitude,
                                      );

                                      if (distance > _maxDistance) {
                                        return Container(); // Skip barbers beyond max distance
                                      }

                                      final barberId = barber.id;
                                      final barberPrices =
                                          _selectedServices.map((service) {
                                        final price = prices[service.id]
                                                ?[barberId] ??
                                            service.price;
                                        return '${service.name}: ${price.toStringAsFixed(2)}';
                                      }).join(', ');

                                      final isSelected =
                                          barberId == _selectedBarberId;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0, horizontal: 16.0),
                                        child: Card(
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          color: isSelected
                                              ? Colors.orange[50]
                                              : Colors.white,
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.all(16.0),
                                            leading: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.orange,
                                                  width: 2,
                                                ),
                                              ),
                                              child: ClipOval(
                                                child:
                                                    barber.imageUrl.isNotEmpty
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Shop: ${barber.shopName}\nAddress: ${barber.address}\nDistance: ${distance.toStringAsFixed(2)} km', // Display the distance here
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
                                                      itemBuilder:
                                                          (context, index) =>
                                                              const Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                      ),
                                                      itemCount: 5,
                                                      itemSize: 20.0,
                                                      direction:
                                                          Axis.horizontal,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(barber.rating
                                                        .toStringAsFixed(1)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            trailing: isSelected
                                                ? const Icon(Icons.check_circle,
                                                    color: Colors.green)
                                                : null,
                                            onTap: () {
                                              setState(() {
                                                if (_selectedBarberId == barber.id) {
                                                  // If the barber is already selected, unselect it
                                                  _selectedBarberId = null;
                                                  _selectedBarber = null;
                                                } else {
                                                  // Select the tapped barber
                                                  _selectedBarberId = barber.id;
                                                  _selectedBarber = barber;
                                                }
                                                print('Selected Barber ID: $_selectedBarberId'); // Debugging print
                                              });
                                            },

                                          ),
                                        ),
                                      );
                                    },
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
              ],
            ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Visibility(
            visible:
                _selectedBarberId != null, // Show only if a barber is selected
            child: Button(
              onPressed: () {
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
              },
              child: const Text('Confirm'),
            ),
          ),
        ),
      ),
    );
  }
}
