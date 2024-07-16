import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/models/service_model.dart';

class Appointment {
  String id;
  DateTime date;
  List<Service> services; // List of Service objects
  String address;
  String phoneNumber;
  String uid;
  String time;
  String clientName;
  String barberId;
  String barberName;
  String barberImageUrl;

  Appointment({
    required this.id,
    required this.date,
    required this.services,
    required this.address,
    required this.phoneNumber,
    required this.uid,
    required this.time,
    required this.clientName,
    required this.barberId,
    required this.barberName,
    required this.barberImageUrl,
  });

  // Convert Appointment object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date':
          Timestamp.fromDate(date), // Convert DateTime to Firestore Timestamp
      'services': services.map((service) => service.toMap()).toList(),
      'address': address,
      'phoneNumber': phoneNumber,
      'uid': uid,
      'time': time,
      'clientName': clientName,
      'barberId': barberId,
      'barberName': barberName,
      'barberImageUrl': barberImageUrl,
    };
  }

  // Create Appointment object from Firestore snapshot
  static Appointment fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return Appointment(
      id: data['id'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      services: (data['services'] as List<dynamic>).map((serviceData) {
        return Service.fromMap(serviceData as Map<String, dynamic>);
      }).toList(),
      address: data['address'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      uid: data['uid'] ?? '',
      time: data['time'] ?? '',
      clientName: data['clientName'] ?? '',
      barberId: data['barberId'] ?? '',
      barberName: data['barberName'] ?? '',
      barberImageUrl: data['barberImageUrl'] ?? '',
    );
  }
}
