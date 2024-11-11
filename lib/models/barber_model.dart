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
  double rating;
  int ratingCount;

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
    required this.latitude, // Make sure latitude is a required parameter
    required this.longitude, // Make sure longitude is a required parameter
    this.rating = 0.0,
    this.ratingCount = 0,
  });

  factory Barber.fromSnapshot(doc) {
    return Barber(
      id: doc['id'] ?? '',
      name: doc['name'] ?? '',
      phoneNumber: doc['phoneNumber'] ?? '',
      address: doc['address'] ?? '',
      imageUrl: doc['imageUrl'] ?? '',
      token: doc['token'] ?? '',
      email: doc['email'] ?? '',
      userType: doc['userType'] ?? '3',
      shopName: doc['shopName'] ?? '',
      latitude: doc['location']?['latitude']?.toDouble() ?? 0.0,
      longitude: doc['location']?['longitude']?.toDouble() ?? 0.0,
      rating: doc['rating']?.toDouble() ?? 0.0,
      ratingCount: doc['ratingCount'] ?? 0,
    );
  }

  factory Barber.fromMap(Map<String, dynamic> data) {
    return Barber(
      id: data['id'] ?? '',
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
      rating: data['rating']?.toDouble() ?? 0.0,
      ratingCount: data['ratingCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
      'rating': rating,
      'ratingCount': ratingCount,
    };
  }
}
