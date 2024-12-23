import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:online_barber_app/models/barber_model.dart';
import 'package:online_barber_app/models/service_model.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/user/book_appointment.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


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
  double _maxDistance = 10.0; // Default distance (in km)
  bool _isLoading = false;

  List<Barber> barbers = [];
  Map<String, bool> approvalStatus = {};
  Map<String, Map<String, double>> prices = {};

  @override
  void initState() {
    super.initState();
    _selectedServices = widget.selectedServices;
    _loadDataInBackground();
  }

  Future<void> _loadDataInBackground() async {
    // Fetch current location
    await _getCurrentLocation();

    // Fetch barber list and prices in the background while showing loading indicator
    _fetchData();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error(AppLocalizations.of(context)!.locationServicesDisabled);
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error(AppLocalizations.of(context)!.locationPermissionsDenied);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(AppLocalizations.of(context)!.locationPermissionsPermanentlyDenied);
    }

    _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {});
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch barber data
      final barberList = await getBarbers().first;

      // Fetch prices for the selected services
      final fetchedPrices = await _getBarberPrices(_selectedServices);

      // Check barber approval status
      final approvals = {
        for (var barber in barberList)
          barber.name: await _isBarberApproved(barber.name)
      };

      setState(() {
        barbers = barberList;
        prices = fetchedPrices;
        approvalStatus = approvals;
        _isLoading = false;
      });
    } catch (e) {
      log('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
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
        }) ?? {};

        prices[service.id] = barberPrices;
      }
    } catch (e) {
      log('Error fetching barber prices: $e');
      rethrow;
    }

    return prices;
  }

  Future<bool> _isBarberApproved(String barberName) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('claim_business')
        .where('barberName', isEqualTo: barberName)
        .where('status', isEqualTo: 'approved')
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  double _calculateDistanceTo(Barber barber) {
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      barber.latitude,
      barber.longitude,
    ) / 1000; // convert to km
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (_isLoading || _currentPosition == null) {
      return const Scaffold(
        body: Center(child: LoadingDots()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(localizations!.selectBarber)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  localizations.maxDistance(_maxDistance.toStringAsFixed(1)),
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
            child: ListView.builder(
              itemCount: barbers.length,
              itemBuilder: (context, index) {
                final barber = barbers[index];
                final isApproved = approvalStatus[barber.name] ?? false;
                final distance = _calculateDistanceTo(barber);

                if (distance > _maxDistance) return Container(); // Skip if too far

                return BarberListTile(
                  barber: barber,
                  isApproved: isApproved,
                  distance: distance,
                  prices: _selectedServices.map((s) => prices[s.id]?[barber.id] ?? s.price).toList(),
                  isSelected: barber.id == _selectedBarberId,
                  onSelect: () => setState(() {
                    _selectedBarberId = barber.id;
                    _selectedBarber = barber;
                  }),
                  selectedServices: _selectedServices,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Visibility(
            visible: _selectedBarberId != null,
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
              child: Text(localizations.confirm),
            ),
          ),
        ),
      ),
    );
  }
}

class BarberListTile extends StatelessWidget {
  final Barber barber;
  final bool isApproved;
  final double distance;
  final List<Service> selectedServices;
  final List<double> prices;  // The list holds prices for each selected service.
  final bool isSelected;
  final VoidCallback onSelect;

  const BarberListTile({super.key, 
    required this.barber,
    required this.isApproved,
    required this.distance,
    required this.selectedServices,
    required this.prices,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // Display the price for each selected service for the barber
    final servicePriceWidgets = List<Widget>.generate(selectedServices.length, (index) {
      final price = prices[index];
      return Text(
        '${selectedServices[index].name}: ${price.toStringAsFixed(2)}',  // Remove the dollar sign
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      );
    });


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: isSelected ? Colors.blue.shade100 : Colors.white,
        child: ListTile(
          onTap: onSelect,
          leading: CircleAvatar(
            backgroundImage: NetworkImage(barber.imageUrl),
            radius: 30,
          ),
          title: Text(barber.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...servicePriceWidgets,
              const SizedBox(height: 5),
              Text(
                '${distance.toStringAsFixed(1)} km  ',
                style: TextStyle(color: isApproved ? Colors.green : Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
