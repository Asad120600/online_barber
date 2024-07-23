import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      print('Error fetching barber prices: $e');
      rethrow; // Re-throw the exception to be caught by FutureBuilder
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
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  print('Error fetching barbers: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No barbers found'));
                } else {
                  return FutureBuilder<Map<String, Map<String, double>>>(
                    future: _getBarberPrices(_selectedServices),
                    builder: (context, priceSnapshot) {
                      if (priceSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (priceSnapshot.hasError) {
                        print('Error fetching barber prices: ${priceSnapshot.error}');
                        return Center(child: Text('Error: ${priceSnapshot.error}'));
                      } else if (!priceSnapshot.hasData) {
                        return const Center(child: Text('No pricing data found'));
                      } else {
                        final prices = priceSnapshot.data!;

                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            Barber barber = snapshot.data![index];

                            // Get the barber's prices for the selected services
                            final barberPrices = _selectedServices.map((service) {
                              final price = prices[service.id]?[barber.id] ?? service.price;
                              return '${service.name}: ${price.toStringAsFixed(2)}'; // \$
                            }).join(', ');

                            final isSelected = barber.id == _selectedBarberId;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue[100] : Colors.white,
                                  border: Border.all(
                                    color: isSelected ? Colors.blue : Colors.grey,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: ListTile(
                                  leading: barber.imageUrl.isNotEmpty
                                      ? CircleAvatar(backgroundImage: NetworkImage(barber.imageUrl))
                                      : const CircleAvatar(child: Icon(Icons.person)),
                                  title: Text(barber.name),
                                  subtitle: Text(
                                    'Prices: $barberPrices\nAddress: ${barber.address ?? 'N/A'}\nShop: ${barber.shopName ?? 'N/A'}',
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedBarberId = barber.id;
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
                        barberAddress: _selectedBarber!.address ?? 'N/A',
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
