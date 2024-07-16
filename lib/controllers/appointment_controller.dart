import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/models/appointment_model.dart';
import 'package:online_barber_app/models/barber_model.dart'; // Adjust with your barber model import

class AppointmentController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference appointmentsCollection =
  FirebaseFirestore.instance.collection('appointments');
  final CollectionReference barbersCollection =
  FirebaseFirestore.instance.collection('barbers'); // Collection reference for barbers

  Future<void> bookAppointment(Appointment appointment) async {
    try {
      // Fetch all barbers
      QuerySnapshot barberSnapshot = await barbersCollection.get();
      List<Barber> barbers = barberSnapshot.docs
          .map((doc) => Barber.fromSnapshot(doc))
          .toList();

      // Find selected barber details
      Barber? selectedBarber = barbers.firstWhere(
            (barber) => barber.id == appointment.barberId,
        orElse: () => Barber(id: '', name: '', imageUrl: '', phoneNumber: '', address: ''), // Default if not found
      );

      // Add barber details to appointment
      appointment.barberName = selectedBarber.name;
      appointment.barberImageUrl = selectedBarber.imageUrl;

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

  Stream<List<Appointment>> getAllAppointments() {
    return appointmentsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Appointment.fromSnapshot(doc)).toList();
    });
  }
}
