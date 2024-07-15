import 'package:flutter/material.dart';
import '../../../controllers/barber_service.dart';
import '../../../models/barber_model.dart';
import '../../../utils/barber_card.dart';

class BarberListScreen extends StatelessWidget {
  final BarberService _barberService = BarberService();

  BarberListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barbers'),
      ),
      body: StreamBuilder<List<Barber>>(
        stream: _barberService.getBarbers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final barbers = snapshot.data ?? [];

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
            ),
            itemCount: barbers.length,
            itemBuilder: (context, index) {
              return BarberCard(barber: barbers[index]);
            },
          );
        },
      ),
    );
  }
}
