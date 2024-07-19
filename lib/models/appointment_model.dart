import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/models/service_model.dart';

class Appointment {
  final String id;
  final Timestamp date; // Use Timestamp for date
  final String time;
  final List<Service> services;
  final String address;
  final String phoneNumber;
  final String uid;
  final String barberName;
  final String barberAddress;
  final String clientName;
  final String barberId;

  Appointment({
    required this.id,
    required this.date,
    required this.time,
    required this.services,
    required this.address,
    required this.phoneNumber,
    required this.uid,
    required this.barberName,
    required this.barberAddress,
    required this.clientName,
    required this.barberId,
  });

  // Convert Appointment to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date, // Store as Timestamp
      'time': time,
      'services': services.map((service) => service.toMap()).toList(),
      'address': address,
      'phoneNumber': phoneNumber,
      'uid': uid,
      'barberName': barberName,
      'barberAddress': barberAddress,
      'barberId': barberId,
      'clientName': clientName,
    };
  }

  // Create an Appointment from a Firestore snapshot
  factory Appointment.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return Appointment(
      id: data['id'] ?? '',
      date: data['date'] is Timestamp ? data['date'] as Timestamp : Timestamp.now(),
      time: data['time'] ?? '',
      services: (data['services'] as List<dynamic>? ?? []).map((serviceData) {
        return Service.fromMap(serviceData as Map<String, dynamic>);
      }).toList(),
      address: data['address'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      uid: data['uid'] ?? '',
      barberName: data['barberName'] ?? '',
      barberAddress: data['barberAddress'] ?? '',
      barberId: data['barberId'] ?? '',
      clientName: data['clientName'] ?? '',
    );
  }
}
