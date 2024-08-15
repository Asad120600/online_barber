import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:online_barber_app/models/appointment_model.dart';

class RemovedAppointmentsScreen extends StatelessWidget {
  final List<Appointment> removedAppointments;

  const RemovedAppointmentsScreen({super.key, required this.removedAppointments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Removed Appointments'),
      ),
      body: removedAppointments.isEmpty
          ? const Center(
        child: Text('No removed appointments.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: removedAppointments.length,
        itemBuilder: (context, index) {
          Appointment appointment = removedAppointments[index];

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
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Date: ${DateFormat.yMd().format(appointment.date.toDate())}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                          'Time: ${appointment.time}',
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
                          'Barber Name: ${appointment.barberName}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Address: ${appointment.address}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Phone Number: ${appointment.phoneNumber}',
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
                          'Total Price: ${appointment.totalPrice.toStringAsFixed(2)}',
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
                          'Home Service: ${appointment.isHomeService ? 'Yes' : 'No'}',
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
                          'Status: ${appointment.status}',
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
      ),
    );
  }
}
