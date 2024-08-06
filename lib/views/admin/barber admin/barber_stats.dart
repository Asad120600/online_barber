import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/models/barber_model.dart';

class BarberStatsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BarberStatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barber Stats'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('barbers').snapshots(),
        builder: (context, barberSnapshot) {
          if (barberSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!barberSnapshot.hasData || barberSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No barbers found.'));
          }

          List<Barber> barbers = barberSnapshot.data!.docs
              .map((doc) => Barber.fromSnapshot(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: barbers.length,
            itemBuilder: (context, index) {
              Barber barber = barbers[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: FutureBuilder<int>(
                    future: _getDoneAppointmentsCount(barber.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(
                          title: Text('Loading...'),
                        );
                      }

                      if (snapshot.hasError) {
                        return ListTile(
                          title: Text(barber.name),
                          subtitle: Text('Error loading done appointments'),
                          trailing: const Icon(Icons.error, color: Colors.red),
                        );
                      }

                      int doneAppointmentsCount = snapshot.data ?? 0;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(barber.imageUrl),
                          radius: 30,
                        ),
                        title: Text(
                          barber.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        subtitle: Text(
                          'Done appointments: $doneAppointmentsCount',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14.0,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<int> _getDoneAppointmentsCount(String barberId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .where('status', isEqualTo: 'Done')
        .get();

    return querySnapshot.docs.length;
  }
}
