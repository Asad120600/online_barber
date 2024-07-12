import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/barber_model.dart';

class BarberService {
  final CollectionReference _barberCollection =
  FirebaseFirestore.instance.collection('barbers');

  Future<void> addBarber(Barber barber) async {
    await _barberCollection.doc(barber.id).set(barber.toMap());
  }

  Future<void> removeBarber(String id) async {
    await _barberCollection.doc(id).delete();
  }

  Stream<List<Barber>> getBarbers() {
    return _barberCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Barber.fromSnapshot(doc)).toList());
  }
}
