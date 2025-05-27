// class Barber {
//   final String id;
//   final String name;
//   final String phoneNumber;
//   final String address;
//   final String imageUrl;
//   final String token;
//   final String email;
//   final String userType;
//   final String shopName;
//   final double latitude;
//   final double longitude;
//   // double? rating; // Nullable rating
//   // int? ratingCount; // Nullable ratingCount

//   Barber({
//     required this.id,
//     required this.name,
//     required this.phoneNumber,
//     required this.address,
//     required this.imageUrl,
//     required this.token,
//     required this.email,
//     required this.userType,
//     required this.shopName,
//     required this.latitude, // Make sure latitude is a required parameter
//     required this.longitude, // Make sure longitude is a required parameter
//     // this.rating,  // Make rating nullable
//     // this.ratingCount,  // Make ratingCount nullable
//   });

// factory Barber.fromSnapshot(doc) {
//   return Barber(
//     id: doc['uid'] ?? '',
//     name: doc['name'] ?? '',
//     phoneNumber: doc['phoneNumber'] ?? '',
//     address: doc['address'] ?? '',
//     imageUrl: doc['imageUrl'] ?? '',
//     token: doc['token'] ?? '',
//     email: doc['email'] ?? '',
//     userType: doc['userType'] ?? '3',
//     shopName: doc['shopName'] ?? '',
//     latitude: doc['location']?['latitude']?.toDouble() ?? 0.0,
//     longitude: doc['location']?['longitude']?.toDouble() ?? 0.0,
//     // rating: doc['rating'] != null ? doc['rating'].toDouble() : 0.0,  // Check if rating exists
//     // ratingCount: doc['ratingCount'] ?? 0,  // Default to 0 if ratingCount is missing
//   );
// }

//   factory Barber.fromMap(Map<String, dynamic> data) {
//     return Barber(
//       id: data['uid'] ?? '',
//       name: data['name'] ?? '',
//       phoneNumber: data['phoneNumber'] ?? '',
//       address: data['address'] ?? '',
//       imageUrl: data['imageUrl'] ?? '',
//       token: data['token'] ?? '',
//       email: data['email'] ?? '',
//       userType: data['userType'] ?? '3',
//       shopName: data['shopName'] ?? '',
//       latitude: data['location']?['latitude']?.toDouble() ?? 0.0,
//       longitude: data['location']?['longitude']?.toDouble() ?? 0.0,
//       // rating: data['rating'] != null ? (data['rating'] as num).toDouble() : null, // Nullable rating
//       // ratingCount: data['ratingCount'] != null ? data['ratingCount'] as int : null, // Nullable ratingCount
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'uid': id,
//       'name': name,
//       'phoneNumber': phoneNumber,
//       'address': address,
//       'imageUrl': imageUrl,
//       'token': token,
//       'email': email,
//       'userType': userType,
//       'shopName': shopName,
//       'location': {
//         'latitude': latitude,
//         'longitude': longitude,
//       },
//       // 'rating': rating,  // Nullable rating
//       // 'ratingCount': ratingCount,  // Nullable ratingCount
//     };
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';

class Barber {
  final String id;
  final String name;
  final String phoneNumber;
  final String address;
  final String imageUrl;
  final String token;
  final String email;
  final String userType;
  final String shopName;
  final double latitude;
  final double longitude;
  // double? rating;
  // int? ratingCount;

  Barber({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.imageUrl,
    required this.token,
    required this.email,
    required this.userType,
    required this.shopName,
    required this.latitude,
    required this.longitude,
    // this.rating,
    // this.ratingCount,
  });

  /// ✅ From Firestore DocumentSnapshot
  factory Barber.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Barber(
      id: doc.id, // ✅ use doc ID instead of data['uid']
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      token: data['token'] ?? '',
      email: data['email'] ?? '',
      userType: data['userType'] ?? '3',
      shopName: data['shopName'] ?? '',
      latitude: data['location']?['latitude']?.toDouble() ?? 0.0,
      longitude: data['location']?['longitude']?.toDouble() ?? 0.0,
      // rating: data['rating'] != null ? (data['rating'] as num).toDouble() : null,
      // ratingCount: data['ratingCount'] != null ? data['ratingCount'] as int : null,
    );
  }

  /// Optional: if using raw maps
  factory Barber.fromMap(Map<String, dynamic> data) {
    return Barber(
      id: data['uid'] ?? '', // here you may still want 'uid' field
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      token: data['token'] ?? '',
      email: data['email'] ?? '',
      userType: data['userType'] ?? '3',
      shopName: data['shopName'] ?? '',
      latitude: data['location']?['latitude']?.toDouble() ?? 0.0,
      longitude: data['location']?['longitude']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'imageUrl': imageUrl,
      'token': token,
      'email': email,
      'userType': userType,
      'shopName': shopName,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
    };
  }
}
