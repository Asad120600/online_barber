import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/models/user_model.dart';

class AdminModel extends BaseUserModel {
  // Additional fields for Admin
  // For example, admin-specific permissions or roles can be added here

  AdminModel({
    required super.uid,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.userType,
    required super.phone,
    // Add any additional admin-specific fields here
  });

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>; // Use correct data type

    return AdminModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      userType: data['userType'] ?? '1',
      phone: data['phone'] ?? '',
      // Initialize additional fields here
    );
  }

  @override
  Map<String, dynamic> toMap() {
    var map = super.toMap();
    // Add admin-specific fields to the map
    return map;
  }
}
