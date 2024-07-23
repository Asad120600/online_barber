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

class _BarberPanelState extends State<BarberPanel> with SingleTickerProviderStateMixin {
  late final AppointmentController _appointmentController;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _appointmentController = AppointmentController();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
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
        body: const Center(
          child: Text('Barber ID is empty or user not authenticated.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Bookings'),
        bottom: _tabController != null
            ? TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today Bookings'),
            Tab(text: 'Upcoming'),
            Tab(text: 'History'),
          ],
        )
            : null,
      ),
      endDrawer: BarberDrawer(screenWidth: screenWidth),
      body: _tabController != null
          ? TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentsTab(_filterAppointmentsForToday, 'Today'),
          _buildAppointmentsTab(_filterAppointmentsForUpcoming, 'Upcoming'),
          _buildAppointmentsTab(_filterAppointmentsForHistory, 'History'),
        ],
      )
          : const Center(child: Text('Failed to initialize tabs.')),
    );
  }

  Widget _buildAppointmentsTab(List<Appointment> Function(List<Appointment>) filterFunction, String tabType) {
    return StreamBuilder<List<Appointment>>(
      stream: _appointmentController.getAppointmentsByBarberID(widget.barberId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          log('Error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No Bookings found.'));
        } else {
          List<Appointment> appointments = snapshot.data!;
          List<Appointment> filteredAppointments = filterFunction(appointments);

          // Sort filtered appointments by date and time
          filteredAppointments.sort((a, b) {
            DateTime dateTimeA = _createDateTime(a.date.toDate(), a.time);
            DateTime dateTimeB = _createDateTime(b.date.toDate(), b.time);
            return dateTimeA.compareTo(dateTimeB);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: filteredAppointments.length,
            itemBuilder: (context, index) {
              Appointment appointment = filteredAppointments[index];
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
                        if (appointment.isHomeService) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Address: ${appointment.address ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Home Service: ${appointment.isHomeService ? 'Yes' : 'No'}',
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
                        Text(
                          'Total Price: ${appointment.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
                        const SizedBox(height: 8),
                        if (tabType == 'Upcoming') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: Add reschedule functionality
                                },
                                child: const Text('Reschedule'),
                              ),
                            ],
                          ),
                        ] else if (tabType == 'Today') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (appointment.status != 'Confirmed')
                                ElevatedButton(
                                  onPressed: () {
                                    // TODO: Add confirm functionality
                                  },
                                  child: const Text('Confirm'),
                                ),
                              const SizedBox(width: 8),
                              if (appointment.status != 'Cancelled')
                                ElevatedButton(
                                  onPressed: () {
                                    // TODO: Add cancel functionality
                                  },
                                  child: const Text('Cancel'),
                                ),
                              const SizedBox(width: 8),
                              if (appointment.status != 'Done')
                                ElevatedButton(
                                  onPressed: () => _updateStatusAndMoveToHistory(appointment.id, 'Done'),
                                  child: const Text('Done'),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  void _updateStatusAndMoveToHistory(String appointmentId, String status) async {
    try {
      await _appointmentController.updateAppointmentStatus(appointmentId, status);
      setState(() {}); // Refresh the UI
    } catch (e) {
      log('Error updating status: $e');
      // Show error message to the user
    }
  }

  List<Appointment> _filterAppointmentsForToday(List<Appointment> appointments) {
    DateTime now = DateTime.now();
    return appointments.where((appointment) {
      DateTime appointmentDate = appointment.date.toDate();
      return appointmentDate.year == now.year &&
          appointmentDate.month == now.month &&
          appointmentDate.day == now.day &&
          appointment.status != 'Done';
    }).toList();
  }

  List<Appointment> _filterAppointmentsForUpcoming(List<Appointment> appointments) {
    DateTime now = DateTime.now();
    return appointments.where((appointment) {
      DateTime appointmentDate = appointment.date.toDate();
      return appointmentDate.isAfter(now) && appointment.status != 'Done';
    }).toList();
  }

  List<Appointment> _filterAppointmentsForHistory(List<Appointment> appointments) {
    DateTime now = DateTime.now();
    return appointments.where((appointment) {
      DateTime appointmentDate = appointment.date.toDate();
      // Include only appointments marked as "Done" or those in the past not marked as "Confirmed"
      return (appointmentDate.isBefore(now) && appointment.status != 'Confirmed' && appointmentDate.day != now.day) ||
          appointment.status == 'Done';
    }).toList();
  }

  DateTime _createDateTime(DateTime date, String? time) {
    if (time == null || time.isEmpty) return date;
    try {
      final timeFormat = DateFormat.jm();
      final timeParsed = timeFormat.parse(time);
      return DateTime(date.year, date.month, date.day, timeParsed.hour, timeParsed.minute);
    } catch (e) {
      log('Error parsing time: $e');
      return date;
    }
  }
}
