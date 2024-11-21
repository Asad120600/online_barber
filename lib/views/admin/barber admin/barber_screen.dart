import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:online_barber_app/views/admin/barber%20admin/barber_panel_admin.dart';
import '../../../controllers/barber_controller.dart';
import '../../../models/barber_model.dart';
import '../../../utils/barber_card.dart';

class BarberListScreen extends StatelessWidget {
  final BarberController _barberService = BarberController();

  BarberListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.barbers),
      ),
      body: StreamBuilder<List<Barber>>(
        stream: _barberService.getBarbers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${AppLocalizations.of(context)!.error}: ${snapshot.error}',
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final barbers = snapshot.data ?? [];

          if (barbers.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.no_barbers_found),
            );
          }

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
                      builder: (context) => BarberPanelAdmin(
                        barberId: barbers[index].id,
                      ),
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
