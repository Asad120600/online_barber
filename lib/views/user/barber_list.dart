import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  bool _isLoading = false;

  List<Barber> barbers = [];
  List<Barber> filteredBarbers = [];
  Map<String, bool> approvalStatus = {};
  Map<String, Map<String, double>> prices = {};
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedServices = widget.selectedServices;
    _loadDataInBackground();
    searchController.addListener(_filterBarbers);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDataInBackground() async {
    await _fetchData();
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
        filteredBarbers = barberList;
        prices = fetchedPrices;
        approvalStatus = approvals;
        _isLoading = false;
      });
    } catch (e) {
      log('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterBarbers() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredBarbers = barbers
          .where((barber) =>
              barber.shopName.toLowerCase().contains(query) ||
              barber.name.toLowerCase().contains(query))
          .toList();
    });
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

  Future<bool> _isBarberApproved(String barberName) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('claim_business')
        .where('barberName', isEqualTo: barberName)
        .where('status', isEqualTo: 'approved')
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingDots()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(localizations!.selectBarber)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by shop name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredBarbers.length,
              itemBuilder: (context, index) {
                final barber = filteredBarbers[index];
                final isApproved = approvalStatus[barber.name] ?? false;

                return BarberListTile(
                  barber: barber,
                  isApproved: isApproved,
                  prices: _selectedServices
                      .map((s) => prices[s.id]?[barber.id] ?? s.price)
                      .toList(),
                  isSelected: barber.id == _selectedBarberId,
                  onSelect: () => setState(() {
                    if (_selectedBarberId == barber.id) {
                      _selectedBarberId = null;
                      _selectedBarber = null;
                    } else {
                      _selectedBarberId = barber.id;
                      _selectedBarber = barber;
                    }
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
  final List<Service> selectedServices;
  final List<double> prices;
  final bool isSelected;
  final VoidCallback onSelect;

  const BarberListTile({
    super.key,
    required this.barber,
    required this.isApproved,
    required this.selectedServices,
    required this.prices,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final servicePriceWidgets =
        List<Widget>.generate(selectedServices.length, (index) {
      final price = prices[index];
      return Text(
        '${selectedServices[index].name}: ${price.toStringAsFixed(2)}',
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
            radius: 30,
            backgroundImage: barber.imageUrl.isNotEmpty
                ? NetworkImage(barber.imageUrl)
                : null,
            child: barber.imageUrl.isEmpty
                ? const Icon(Icons.content_cut, size: 30, color: Colors.grey)
                : null,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(barber.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              if (barber.shopName.isNotEmpty)
                Text(barber.shopName,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...servicePriceWidgets,
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}
