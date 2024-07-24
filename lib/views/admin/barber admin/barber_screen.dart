import 'package:flutter/material.dart';
import 'package:online_barber_app/views/admin/barber%20admin/barber_panel_admin.dart';
import '../../../controllers/barber_controller.dart';
import '../../../models/barber_model.dart';
import '../../../utils/barber_card.dart';
import '../../barber/barber_panel.dart';  // Import the BarberPanel screen

class BarberListScreen extends StatelessWidget {
  final BarberController _barberService = BarberController();

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
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BarberPanelAdmin(barberId: barbers[index].id), // Navigate to BarberPanel
                    ),
                  );
                },
                child: BarberCard(barber: barbers[index]),
              );
            },
          );
        },
      ),
    );
  }
}
