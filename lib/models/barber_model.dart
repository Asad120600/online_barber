import 'package:cloud_firestore/cloud_firestore.dart';

class Barber {
  final String id;
  final String name;
  final String phoneNumber;
  final String address;
  final String imageUrl;

  Barber({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'imageUrl': imageUrl,
    };
  }

  factory Barber.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Null check and provide default values if necessary
    return Barber(
      id: data['id'] ?? '', // Provide a default empty string
      name: data['name'] ?? 'Unknown', // Provide a default name
      phoneNumber: data['phoneNumber'] ?? 'No phone number', // Provide a default phone number
      address: data['address'] ?? 'No address', // Provide a default address
      imageUrl: data['imageUrl'] ?? '', // Provide a default empty string
    );
  }

  Barber copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? address,
    String? imageUrl,
  }) {
    return Barber(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
