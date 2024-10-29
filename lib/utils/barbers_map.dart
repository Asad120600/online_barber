import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BarberLocationMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String barberName;

  const BarberLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.barberName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Location of $barberName')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: MarkerId(barberName),
            position: LatLng(latitude, longitude),
            infoWindow: InfoWindow(title: barberName),
          ),
        },
      ),
    );
  }
}
