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

    return Barber(
      id: doc.id,
      name: data['name'] ?? 'Unknown', // Default to 'Unknown' if name is missing
      phoneNumber: data['phoneNumber'] ?? '', // Default to empty string if phoneNumber is missing
      address: data['address'] ?? '', // Default to empty string if address is missing
      imageUrl: data['imageUrl'] ?? '', // Default to empty string if imageUrl is missing
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
