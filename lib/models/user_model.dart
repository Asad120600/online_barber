import 'package:cloud_firestore/cloud_firestore.dart';

class BaseUserModel {
  String uid; // Add uid field
  String email;
  String firstName;
  String lastName;
  String userType;

  BaseUserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userType,
  });

  factory BaseUserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return BaseUserModel(
      uid: doc.id, // Assign uid from document id
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      userType: data['userType'] ?? '3',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid, // Include uid in toMap method if needed
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'userType': userType,
    };
  }
}
