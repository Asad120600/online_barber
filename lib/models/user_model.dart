import 'package:cloud_firestore/cloud_firestore.dart';

class BaseUserModel {
  String uid; // Add uid field
  String email;
  String firstName;
  String lastName;
  String userType;
  String phone;
  String token;

  BaseUserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userType,
    required this.phone,
    required this.token,

  });

  factory BaseUserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return BaseUserModel(
      uid: doc.id, // Assign uid from document id
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      userType: data['userType'] ?? '3',
      phone: data['phone'] ?? '',
      token: data['token'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid, // Include uid in toMap method if needed
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'userType': userType,
      'phone' : phone,
      'token' : token,
    };
  }
}
