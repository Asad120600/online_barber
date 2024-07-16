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

  factory Barber.fromSnapshot(DocumentSnapshot doc) {
    return Barber(
      id: doc['id'] ?? '',
      name: doc['name'] ?? '',
      phoneNumber: doc['phoneNumber'] ?? '',
      address: doc['address'] ?? '',
      imageUrl: doc['imageUrl'] ?? '',
    );
  }

  factory Barber.fromMap(Map<String, dynamic> data) {
    return Barber(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'imageUrl': imageUrl,
    };
  }
}
