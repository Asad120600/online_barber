import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/barber_model.dart';

class BarberController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(File image) async {
    try {
      final storageRef = _storage.ref().child('barber_images/${DateTime.now().toIso8601String()}');
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print(e);
      return '';
    }
  }

  Future<void> addBarber(Barber barber) async {
    try {
      await _firestore.collection('barbers').doc(barber.id).set(barber.toMap());
    } catch (e) {
      print(e);
    }
  }

  Future<void> removeBarber(String id) async {
    try {
      await _firestore.collection('barbers').doc(id).delete();
    } catch (e) {
      print(e);
    }
  }

  Stream<List<Barber>> getBarbers() {
    return _firestore.collection('barbers').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Barber.fromMap(doc.data())).toList());
  }
}
