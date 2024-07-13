import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/models/appointment_model.dart';

class AppointmentFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addAppointment(Appointment appointment) async {
    await _firestore
        .collection('appointments')
        .doc(appointment.uid)
        .collection('userAppointments')
        .doc(appointment.id)
        .set(appointment.toMap());
  }

  Future<List<Appointment>> getAppointmentsByUID(String uid) async {
    final querySnapshot = await _firestore
        .collection('appointments')
        .doc(uid)
        .collection('userAppointments')
        .get();

    return querySnapshot.docs
        .map((doc) => Appointment.fromSnapshot(doc))
        .toList();
  }
}
