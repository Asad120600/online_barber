import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/user/home_screen.dart';

class BarberRatingScreen extends StatefulWidget {
  final String barberId;
  final String barberName;
  final String appointmentId; // Add appointmentId

  const BarberRatingScreen({
    super.key,
    required this.barberId,
    required this.barberName,
    required this.appointmentId, // Required parameter
  });

  @override
  _BarberRatingScreenState createState() => _BarberRatingScreenState();
}

class _BarberRatingScreenState extends State<BarberRatingScreen> {
  double _rating = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRatingBottomSheet();
    });
  }

  void _showRatingBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false, // Prevent closing the bottom sheet manually
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rate ${widget.barberName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RatingBar.builder(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (value) {
                      setState(() {
                        _rating = value;
                      });
                    },
                  ),
                  Text('${_rating.toStringAsFixed(1)} / 5'),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const LoadingDots()
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Button(
                        width: 120,
                        onPressed: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>const HomeScreen()));
                        },
                        child: const Text('Cancel'),
                      ),
                      Button(
                      onPressed: _rating > 0 && !_isLoading
            ? () => _submitRating(setState)
                : null,
                        width:120,
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitRating(StateSetter setState) async {
    setState(() {
      _isLoading = true;
    });

    final userId = LocalStorage().getCurrentUserId().toString(); // Replace with actual user ID
    try {
      // Fetch the barber document
      final docSnapshot = await FirebaseFirestore.instance
          .collection('barbers')
          .doc(widget.barberId)
          .get();
      final currentData = docSnapshot.data();

      if (currentData != null) {
        // Calculate new rating
        final currentRating = currentData['rating'] as num? ?? 0;
        final currentRatingCount = currentData['ratingCount'] as int? ?? 0;
        final newRatingCount = currentRatingCount + 1;
        final newRating =
            ((currentRating * currentRatingCount) + _rating) / newRatingCount;

        // Update the barber document with the new rating and count
        await FirebaseFirestore.instance
            .collection('barbers')
            .doc(widget.barberId)
            .update({
          'rating': newRating,
          'ratingCount': newRatingCount,
        });

        // Add rating to the ratings collection
        await FirebaseFirestore.instance.collection('ratings').add({
          'userId': userId,
          'barberId': widget.barberId,
          'rating': _rating,
        });

        // Update the hasBeenRated field in the appointment document
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(widget.appointmentId)
            .update({
          'hasBeenRated': true,
        });

        Navigator.of(context).pop(); // Close bottom sheet
        _showSuccessDialog(); // Show success dialog
      }
    } catch (e) {
      log('Error saving rating: $e');
      Navigator.of(context).pop(); // Close bottom sheet
      _showErrorDialog(); // Show error dialog
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Your rating has been submitted successfully.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                // Navigate to HomeScreen and remove all other routes
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (Route<dynamic> route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text(
              'An error occurred while submitting your rating. Please try again later.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>const HomeScreen()));
},
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(), // Empty body since we're only showing a bottom sheet
    );
  }
}
