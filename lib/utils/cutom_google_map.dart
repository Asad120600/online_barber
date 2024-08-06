import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class CustomGoogleMap extends StatefulWidget {
  @override
  _CustomGoogleMapState createState() => _CustomGoogleMapState();
}

class _CustomGoogleMapState extends State<CustomGoogleMap> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng _selectedLocation = const LatLng(30.1864, 71.4886); // Default location
  late Marker _selectedMarker;
  bool _isFetchingLocation = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedMarker = Marker(
      markerId: const MarkerId('selected-location'),
      position: _selectedLocation,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _selectCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 14.0,
            ),
            markers: {_selectedMarker},
            onTap: _onMapTapped,
            zoomControlsEnabled: false, // Hide zoom buttons
          ),
          if (_isFetchingLocation)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search location',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: _searchLocation,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        shape: const CircleBorder(),
        onPressed: _confirmLocation,
        child: const Icon(Icons.check,color: Colors.black,),
      ),
    );
  }

  Future<void> _selectCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng currentLocation = LatLng(position.latitude, position.longitude);
      _onMapTapped(currentLocation);

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(currentLocation, 14.0));

      setState(() {
        _isFetchingLocation = false;
      });
    } catch (e) {
      print('Error fetching current location: $e');
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _selectedMarker = Marker(
        markerId: const MarkerId('selected-location'),
        position: _selectedLocation,
      );
    });
  }

  Future<void> _confirmLocation() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String address = '${placemark.street}, ${placemark.locality}, ${placemark.country}';
        Navigator.pop(context, address);
      }
    } catch (e) {
      print('Error fetching address: $e');
    }
  }

  Future<void> _searchLocation(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        LatLng newLocation = LatLng(locations.first.latitude, locations.first.longitude);
        _onMapTapped(newLocation);

        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(newLocation, 14.0));
      }
    } catch (e) {
      print('Error searching location: $e');
    }
  }
}