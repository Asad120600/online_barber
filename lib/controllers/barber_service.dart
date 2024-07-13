import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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
    return _barberCollection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Barber.fromSnapshot(doc))
        .toList());
  }

  Future<String> uploadImage(File imageFile) async {
    final storageRef = FirebaseStorage.instance.ref().child('barber_images/${DateTime.now().millisecondsSinceEpoch}');
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask.whenComplete(() => {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }
}
