import 'package:cloud_firestore/cloud_firestore.dart';

class Barber {

  final String id;
  final String name;
  final String phoneNumber;
  final String address;
  final String imageUrl;
  String token;
  String email;
  String userType;
  String shopName;

  Barber({
    required this.email,
    required this.userType,
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.imageUrl,
    required  this.token,
    required  this.shopName,
  });

  factory Barber.fromSnapshot(DocumentSnapshot doc) {
    return Barber(
      id: doc['id'] ?? '',
      name: doc['name'] ?? '',
      email: doc['email'] ?? '',
      phoneNumber: doc['phoneNumber'] ?? '',
      address: doc['address'] ?? '',
      imageUrl: doc['imageUrl'] ?? '',
      userType: doc['userType'] ?? '3',
      token: doc['token'] ?? '',
      shopName: doc['shopName'] ?? '',


    );
  }

  factory Barber.fromMap(Map<String, dynamic> data) {
    return Barber(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      email: data['email'] ?? '',
      userType: data['userType'] ?? '3',
      token: data['token'] ?? '',
      shopName: data['shopName'] ?? '',


    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'imageUrl': imageUrl,
      'email':email,
      'userType':userType,
      'token':token,
      'shopName':shopName,

    };
  }
}
