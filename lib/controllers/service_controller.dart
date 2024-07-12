import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service.dart';

class ServiceController {
  final CollectionReference _servicesCollection =
  FirebaseFirestore.instance.collection('services');

  // Add a new service to Firestore
  Future<void> addService(Service service) async {
    await _servicesCollection.doc(service.id).set(service.toMap());
  }

  // Update an existing service in Firestore
  Future<void> updateService(Service service) async {
    await _servicesCollection.doc(service.id).update(service.toMap());
  }

  // Delete a service from Firestore
  Future<void> deleteService(String serviceId) async {
    await _servicesCollection.doc(serviceId).delete();
  }

  // Stream of all services from Firestore
  Stream<List<Service>> getServicesStream() {
    return _servicesCollection.snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Service.fromSnapshot(doc))
          .toList(),
    );
  }
}
