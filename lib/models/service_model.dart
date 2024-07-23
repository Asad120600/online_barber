import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String name;
  final double price;
  final String category;
  final String? imageUrl;
  final List<Map<String, dynamic>>? barberPrices;
  final bool isHomeService;
  final double homeServicePrice;// List of maps containing barberId and price

  Service({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imageUrl,
    this.barberPrices,
    required this.isHomeService,
    required this.homeServicePrice,
  });

  // Convert a Service object to a Map for Firestore operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'barberPrices': barberPrices,
      'isHomeService': isHomeService,
      'homeServicePrice': homeServicePrice,
    };
  }

  // Create a Service object from a Map
  factory Service.fromMap(Map<String, dynamic> data) {
    return Service(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'],
      isHomeService: data['isHomeService'] ?? false,
      homeServicePrice: (data['homeServicePrice'] ?? 0.0).toDouble(),
      barberPrices: data['barberPrices'] != null ? List<Map<String, dynamic>>.from(data['barberPrices']) : null,
    );
  }

  // Create a Service object from a Firestore document snapshot
  factory Service.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return Service(
      id: snapshot.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'],
      barberPrices: data['barberPrices'] != null ? List<Map<String, dynamic>>.from(data['barberPrices']) : null,
      isHomeService: data['isHomeService'] ?? false,
      homeServicePrice: (data['homeServicePrice'] ?? 0.0).toDouble(),
    );
  }
}
