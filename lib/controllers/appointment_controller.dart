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
        try {
          return Appointment.fromSnapshot(doc);
        } catch (e) {
          // Handle conversion error
          print('Error converting document to Appointment: $e');
          return null;
        }
      }).whereType<Appointment>().toList();
    });
  }

  Stream<List<Appointment>> getAppointmentsByBarberID(String barberId) {
    return appointmentsCollection
        .where('barberId', isEqualTo: barberId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Appointment.fromSnapshot(doc);
        } catch (e) {
          // Handle conversion error
          print('Error converting document to Appointment: $e');
          return null;
        }
      }).whereType<Appointment>().toList();
    });
  }

  Stream<List<Appointment>> getAllAppointments() {
    return appointmentsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Appointment.fromSnapshot(doc);
        } catch (e) {
          // Handle conversion error
          print('Error converting document to Appointment: $e');
          return null;
        }
      }).whereType<Appointment>().toList();
    });
  }

  Future<void> updateAppointmentStatus(String appointmentId,
      String status) async {
    try {
      await appointmentsCollection.doc(appointmentId).update(
          {'status': status});
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).delete();
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }
}
