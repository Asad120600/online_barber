import 'package:flutter/material.dart';
import '../../models/barber_model.dart';

class BarberCard extends StatelessWidget {
  final Barber barber;

  const BarberCard({Key? key, required this.barber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double cardPadding = MediaQuery.of(context).size.width * 0.05;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.all(10.0),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: constraints.maxWidth * 0.15,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: barber.imageUrl != null && barber.imageUrl!.isNotEmpty
                      ? NetworkImage(barber.imageUrl!)
                      : null,
                  child: barber.imageUrl == null || barber.imageUrl!.isEmpty
                      ? Icon(
                    Icons.person,
                    size: constraints.maxWidth * 0.15,
                    color: Colors.grey[700],
                  )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  barber.name ?? 'Unknown Barber',
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        barber.phoneNumber ?? 'No phone number',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.045,
                          color: Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        barber.address ?? 'No address',
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.045,
                          color: Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
