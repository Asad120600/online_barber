// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/models/appointment_model.dart';

class AppointmentController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference appointmentsCollection =
  FirebaseFirestore.instance.collection('appointments');

  Future<void> bookAppointment(Appointment appointment) async {
    try {
      // Convert Appointment object to Map
      Map<String, dynamic> appointmentData = appointment.toMap();

      // Add appointment data to Firestore
      await appointmentsCollection.doc(appointment.id).set(appointmentData);
    } catch (e) {
      // Handle error if any
      throw Exception('Failed to book appointment: $e');
    }
  }

  Stream<List<Appointment>> getAppointmentsByUID(String uid) {
    return appointmentsCollection
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Appointment.fromSnapshot(doc);
      }).toList();
    });
  }

  Stream<List<Appointment>> getAppointmentsByBarberID(String barberId) {
    return appointmentsCollection
        .where('barberId', isEqualTo: barberId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Appointment.fromSnapshot(doc);
      }).toList();
    });
  }

  Stream<List<Appointment>> getAllAppointments() {
    return appointmentsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Appointment.fromSnapshot(doc)).toList();
    });
  }
}
