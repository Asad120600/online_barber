import 'package:cloud_firestore/cloud_firestore.dart';

class Barber {
  String id;
  String name;
  String imageUrl;
  String phoneNumber;
  String address;

  Barber({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.phoneNumber,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }

  factory Barber.fromSnapshot(DocumentSnapshot snapshot) {
    return Barber(
      id: snapshot['id'],
      name: snapshot['name'],
      imageUrl: snapshot['imageUrl'],
      phoneNumber: snapshot['phoneNumber'],
      address: snapshot['address'],
    );
  }
}
