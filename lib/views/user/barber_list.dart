import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/models/barber_model.dart';
import 'package:online_barber_app/models/service_model.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/user/book_appointment.dart';

class BarberList extends StatefulWidget {
  final List<Service> selectedServices;
  const BarberList({super.key, required this.selectedServices});

  @override
  State<BarberList> createState() => _BarberListState();
}

class _BarberListState extends State<BarberList> {
  List<Service> _selectedServices = [];

  Stream<List<Barber>> getBarbers() {
    return FirebaseFirestore.instance.collection('barbers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Barber.fromSnapshot(doc)).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedServices = widget.selectedServices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Barber'),
      ),
      body: StreamBuilder<List<Barber>>(
        stream: getBarbers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No barbers found'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Barber barber = snapshot.data![index];
                return ListTile(
                  leading: barber.imageUrl.isNotEmpty
                      ? CircleAvatar(backgroundImage: NetworkImage(barber.imageUrl))
                      : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(barber.name),
                  subtitle: Text(barber.phoneNumber),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookAppointment(
                          selectedServices: _selectedServices,
                          uid: LocalStorage.getUserID().toString(),
                          selectedBarberName: barber.name,
                          selectedBarberAddress: barber.address,
                          selectedBarberId: barber.id,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
