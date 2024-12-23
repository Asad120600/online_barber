import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geocoding/geocoding.dart'; // Import geocoding package
import 'package:online_barber_app/utils/alert_dialog.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:online_barber_app/utils/cutom_google_map.dart';
import 'package:online_barber_app/utils/loading_dialog.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/barber/barber_panel.dart';

class BarberProfile extends StatefulWidget {
  const BarberProfile({super.key});

  @override
  State<BarberProfile> createState() => _BarberProfileState();
}

class _BarberProfileState extends State<BarberProfile> {
  User? _currentUser;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _shopNameController;
  late TextEditingController _nameController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _imageFile;
  String? _imageUrl;
  double? _rating;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _shopNameController = TextEditingController();
    _nameController = TextEditingController();
    _fetchBarberData();
  }

  void _fetchBarberData() async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('barbers').doc(_currentUser?.uid).get();
      if (snapshot.exists) {
        setState(() {
          _phoneController.text = snapshot['phoneNumber'] ?? '';
          _addressController.text = snapshot['address'] ?? '';
          _shopNameController.text = snapshot['shopName'] ?? '';
          _nameController.text = snapshot['name'] ?? '';
          _imageUrl = snapshot['imageUrl'];
          _rating = snapshot['rating']?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      print('Error fetching barber data: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      }
    });
  }

  Future<void> _updateBarberProfile() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: LoadingDialog(message: 'Profile is Updating'));
      },
    );

    try {
      double? latitude;
      double? longitude;

      // Get latitude and longitude from address
      if (_addressController.text.isNotEmpty) {
        List<Location> locations = await locationFromAddress(_addressController.text);
        latitude = locations.first.latitude;
        longitude = locations.first.longitude;
      }

      if (_imageFile != null) {
        _imageUrl = await _uploadImage(_imageFile!);
      }

      await _firestore.collection('barbers').doc(_currentUser?.uid).set({
        'phoneNumber': _phoneController.text,
        'address': _addressController.text,
        'shopName': _shopNameController.text,
        'name': _nameController.text,
        'imageUrl': _imageUrl,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
      }, SetOptions(merge: true));

      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomAlertDialog(
            title: 'Success',
            content: 'Profile updated successfully',
            confirmButtonText: 'OK',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => BarberPanel(barberId: _currentUser!.uid)),
              );
            },
          );
        },
      );
    } catch (e) {
      print('Error updating barber profile: $e');
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    try {
      String imageName = _currentUser?.uid ?? DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('barber_images/$imageName.jpg');
      await ref.putFile(imageFile);
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Error uploading image');
    }
  }

  Future<void> _openMap() async {
    final address = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomGoogleMap()),
    );
    if (address != null) {
      setState(() {
        _addressController.text = address; // Update the address field with the selected address
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _shopNameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.orange,
                    child: _imageFile != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.file(
                        _imageFile!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                        : _imageUrl != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(
                        _imageUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Icon(
                      Icons.cut, // Barber-related icon
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    icon: const Icon(Icons.person, color: Colors.orange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    icon: const Icon(Icons.phone, color: Colors.orange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    icon: const Icon(Icons.location_on, color: Colors.orange),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.pin_drop_rounded, color: Colors.orange),
                      onPressed: _openMap, // Call the method to open Google Maps
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _shopNameController,
                  decoration: InputDecoration(
                    labelText: 'Shop Name',
                    icon: const Icon(Icons.business, color: Colors.orange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                RatingBar.builder(
                  initialRating: _rating ?? 0.0,
                  minRating: 1,
                  itemCount: 5,
                  itemSize: 40.0,
                  glowColor: Colors.orange,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.orange,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Button(
                  onPressed: _updateBarberProfile,
                  child: const Text('Update Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
