import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:online_barber_app/controllers/appointment_controller.dart';
import 'package:online_barber_app/models/appointment_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:online_barber_app/utils/button.dart';
import 'barber_rating_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentsShow extends StatefulWidget {
  final String uid;

  const AppointmentsShow({super.key, required this.uid});

  @override
  _AppointmentsShowState createState() => _AppointmentsShowState();
}

class _AppointmentsShowState extends State<AppointmentsShow> {
  late final AppointmentController _appointmentController;

  @override
  void initState() {
    super.initState();
    _appointmentController = AppointmentController();
  }

  Future<void> _openBarberLocation(String barberId) async {
    try {
      // Retrieve the barber's location data from Firestore
      DocumentSnapshot barberSnapshot = await FirebaseFirestore.instance
          .collection('barbers')
          .doc(barberId)
          .get();

      if (barberSnapshot.exists) {
        double latitude = barberSnapshot['location.latitude'];
        double longitude = barberSnapshot['location.longitude'];
        String barberName = barberSnapshot['name'];

        // Construct Google Maps URL
        String googleMapsUrl =
            'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

        // Launch Google Maps
        if (await canLaunch(googleMapsUrl)) {
          await launch(googleMapsUrl);
        } else {
          throw 'Could not open Google Maps.';
        }
      }
    } catch (e) {
      log('Error fetching barber location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.errorLoadingBarberLocation)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    if (widget.uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations.appointments),
        ),
        body: const Center(
          child: Text('User ID is empty or user not authenticated.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.appointments),
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: _appointmentController.getAppointmentsByUID(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            log('Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(localizations.noAppointmentsFound));
          } else {
            List<Appointment> appointments = snapshot.data!;

            // Sort appointments by date and time in descending order
            appointments.sort((a, b) {
              DateTime dateTimeA = a.date.toDate().add(_parseTime(a.time));
              DateTime dateTimeB = b.date.toDate().add(_parseTime(b.time));
              return dateTimeB.compareTo(dateTimeA); // Reversed the order here
            });

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                Appointment appointment = appointments[index];

                // Determine the background color based on the appointment status
                Color backgroundColor = Colors.white;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    localizations
                                        .date_e(appointment.date.toDate()),
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    localizations.time(appointment.time),
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.cut, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    localizations
                                        .barberName(appointment.barberName),
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment
                                    .center, // Align items in the center vertically
                                children: [
                                  const Icon(Icons.location_on, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${localizations.address}: ${appointment.address}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.pin_drop_outlined,
                                        color: Colors.orange),
                                    onPressed: () => _openBarberLocation(
                                        appointment.barberId),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${localizations.phoneNumber}: ${appointment.phoneNumber}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.attach_money, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${localizations.totalPrice}: ${appointment.totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                      appointment.isHomeService
                                          ? Icons.home
                                          : Icons.store,
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${localizations.homeService}: ${appointment.isHomeService ? localizations.yes : localizations.no}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.query_stats, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    localizations.status_e(
                                        appointment.status ?? 'Unknown'),
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: appointment.services.isNotEmpty
                                    ? appointment.services.map((service) {
                                        return Chip(
                                          label: Text(service.name ??
                                              localizations.noServices),
                                        );
                                      }).toList()
                                    : [
                                        Chip(
                                            label:
                                                Text(localizations.noServices))
                                      ],
                              ),
                              const SizedBox(height: 16),
                              if (appointment.status == 'Done')
                                Button(
                                  width: 155,
                                  onPressed: appointment.hasBeenRated
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BarberRatingScreen(
                                                      barberId:
                                                          appointment.barberId,
                                                      barberName: appointment
                                                          .barberName,
                                                      appointmentId:
                                                          appointment.id),
                                            ),
                                          ).then((_) {
                                            setState(() {});
                                          });
                                        },
                                  child: Text(
                                    appointment.hasBeenRated
                                        ? localizations.alreadyRated
                                        : localizations.rateBarber,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: appointment.hasBeenRated
                                          ? Colors.white
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (appointment.status == 'Done')
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            margin: const EdgeInsets.all(8.0),
                            padding: const EdgeInsets.all(4.0),
                            child: const Icon(
                              Icons.check,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Duration _parseTime(String? time) {
    if (time == null || time.isEmpty) return Duration.zero;

    try {
      // Remove any leading or trailing whitespace from the time string
      time = time.trim();

      // Parse the time using a DateFormat for 12-hour format with AM/PM
      final format = DateFormat.jm(); // This will handle "hh:mm AM/PM"
      DateTime dateTime = format.parse(time);

      // Return the duration from the parsed DateTime
      return Duration(hours: dateTime.hour, minutes: dateTime.minute);
    } catch (e) {
      // log('Error parsing time: $e');
      return Duration.zero; // Return zero duration if parsing fails
    }
  }
}
