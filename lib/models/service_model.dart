import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String name;
  final double price;
  final String category;
  final String? imageUrl;

  Service({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imageUrl,
  });

  // Convert a Service object to a Map for Firestore operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
    };
  }

  // Create a Service object from a Map
  factory Service.fromMap(Map<String, dynamic> data) {
    return Service(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(), // Ensure price is cast to double
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'],
    );
  }

  // Create a Service object from a Firestore document snapshot
  factory Service.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return Service(
      id: snapshot.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(), // Ensure price is cast to double
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'],
    );
  }
}
