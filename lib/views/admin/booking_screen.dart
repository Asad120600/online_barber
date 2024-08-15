import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:online_barber_app/models/appointment_model.dart';

class BookingScreen extends StatelessWidget {
  final Future<List<Appointment>> appointmentsFuture;
  final Function(int) deleteAppointment;
  final Function(int) toggleReadStatus;

  const BookingScreen({
    Key? key,
    required this.appointmentsFuture,
    required this.deleteAppointment,
    required this.toggleReadStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Appointment>>(
      future: appointmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<Appointment> appointments = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey[200],
          child: ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              Appointment appointment = appointments[index];
              String formattedDate = appointment.date != null
                  ? DateFormat('yyyy-MM-dd').format(appointment.date! as DateTime)
                  : 'Not provided';
              String serviceNames = appointment.services != null
                  ? appointment.services!.map((s) => s.name).join(', ')
                  : 'Not provided';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text('Appointment ID: ${appointment.id ?? 'Not provided'}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8.0),
                      Text('Date: $formattedDate'),
                      const SizedBox(height: 4.0),
                      Text('Services: $serviceNames'),
                      const SizedBox(height: 4.0),
                      Text('Address: ${appointment.address ?? 'Not provided'
                      }'),
                      const SizedBox(height: 4.0),
                      Text('Phone Number: ${appointment.phoneNumber ?? 'Not provided'}'),
                      const SizedBox(height: 4.0),
                      Text('UID: ${appointment.uid ?? 'Not provided'}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => deleteAppointment(index),
                  ),
                  onTap: () => toggleReadStatus(index),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
