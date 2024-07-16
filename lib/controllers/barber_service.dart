import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/barber_model.dart';

class BarberService {
  final CollectionReference _barberCollection =
  FirebaseFirestore.instance.collection('barbers');

  Future<void> addBarber(Barber barber, {File? imageFile}) async {
    try {
      String imageUrl = '';

      // Check if image file is provided and upload to Firebase Storage
      if (imageFile != null) {
        imageUrl = await uploadImage(imageFile);
      }

      // Add barber with image URL to Firestore
      await _barberCollection.doc(barber.id).set({
        ...barber.toMap(),
        'imageUrl': imageUrl,
      });
    } catch (e) {
      throw Exception('Failed to add barber: $e');
    }
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
    try {
      // Generate a unique image path in Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('barber_images/${DateTime.now().millisecondsSinceEpoch}');

      // Upload image file
      await storageRef.putFile(imageFile);

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
