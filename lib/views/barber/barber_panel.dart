import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:online_barber_app/controllers/appointment_controller.dart';
import 'package:online_barber_app/models/appointment_model.dart';
import 'package:online_barber_app/views/barber/barber_drawer.dart';

class BarberPanel extends StatefulWidget {
  final String barberId;
  const BarberPanel({super.key, required this.barberId});

  @override
  State<BarberPanel> createState() => _BarberPanelState();
}

class _BarberPanelState extends State<BarberPanel> {
  late final AppointmentController _appointmentController;

  @override
  void initState() {
    super.initState();
    _appointmentController = AppointmentController();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (widget.barberId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Bookings'),
        ),
        body: Center(
          child: Text('Barber ID is empty or user not authenticated.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Bookings'),
      ),
      endDrawer: BarberDrawer(screenWidth: screenWidth,),
      body: StreamBuilder<List<Appointment>>(
        stream: _appointmentController.getAppointmentsByBarberID(widget.barberId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Bookings found.'));
          } else {
            List<Appointment> appointments = snapshot.data!;

            // Sort appointments by date and time
            appointments.sort((a, b) {
              DateTime dateTimeA = _createDateTime(a.date.toDate(), a.time);
              DateTime dateTimeB = _createDateTime(b.date.toDate(), b.time);
              return dateTimeA.compareTo(dateTimeB);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                Appointment appointment = appointments[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                          Text(
                            'Date: ${DateFormat('dd/MM/yy').format(appointment.date.toDate())}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Time: ${appointment.time}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Client Name: ${appointment.clientName ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Address: ${appointment.address ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Phone Number: ${appointment.phoneNumber ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: appointment.services.isNotEmpty
                                ? appointment.services.map((service) {
                              return Chip(
                                label: Text(service.name ?? 'Unknown'),
                              );
                            }).toList()
                                : [const Chip(label: Text('No services'))],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  // Helper method to create DateTime object from date and time
  DateTime _createDateTime(DateTime date, String? time) {
    if (time == null || time.isEmpty) return date;
    try {
      // Create a DateFormat object for 12-hour time with AM/PM
      final timeFormat = DateFormat.jm(); // 'j:m a' format
      final timeParsed = timeFormat.parse(time);
      return DateTime(date.year, date.month, date.day, timeParsed.hour, timeParsed.minute);
    } catch (e) {
      log('Error parsing time: $e');
      return date;
    }
  }
}
