import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:online_barber_app/controllers/appointment_controller.dart';
import 'package:online_barber_app/models/appointment_model.dart';

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

  @override
  Widget build(BuildContext context) {
    if (widget.uid.isEmpty) {
      // Handle case where uid is empty or user is not authenticated
      return Scaffold(
        appBar: AppBar(
          title: const Text('Appointments'),
        ),
        body: Center(
          child: Text('User ID is empty or user not authenticated.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: _appointmentController.getAppointmentsByUID(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Print detailed error information
            print('Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Appointments found.'));
          } else {
            List<Appointment> appointments = snapshot.data!;

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
                          offset: const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Safely convert Timestamp to DateTime
                          Text(
                            'Date: ${appointment.date != null ? DateFormat.yMd().format(appointment.date.toDate()) : 'N/A'}', // Convert Timestamp to DateTime
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Barber Name: ${appointment.barberName ?? 'N/A'}', // Show barber name
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
                            children: appointment.services != null
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
}
