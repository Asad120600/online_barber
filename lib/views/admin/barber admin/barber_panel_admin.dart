import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:online_barber_app/controllers/appointment_controller.dart';
import 'package:online_barber_app/models/appointment_model.dart';

class BarberPanelAdmin extends StatefulWidget {
  final String barberId;
  const BarberPanelAdmin({super.key, required this.barberId});

  @override
  State<BarberPanelAdmin> createState() => _BarberPanelAdminState();
}

class _BarberPanelAdminState extends State<BarberPanelAdmin> with SingleTickerProviderStateMixin {
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
          leading: IconButton(onPressed: (){
            Navigator.pop(context);
          }, icon: const Icon(Icons.arrow_back)),
          title: const Text('Bookings Barber'),
        ),
        body: const Center(
          child: Text('Barber ID is empty or user not authenticated.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: const Icon(Icons.arrow_back)),
        title: const Text('Bookings Barber'),
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
                child: Stack(
                  children: [
                    Container(
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
                                  'Date: ${DateFormat('dd/MM/yy').format(appointment.date.toDate())}',
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
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Client Name: ${appointment.clientName}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            if (appointment.isHomeService) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.home, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Address: ${appointment.address}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.local_shipping, size: 16),
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
                                const Icon(Icons.info, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Status: ${appointment.status}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: appointment.status == 'Done'
                                        ? Colors.green
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
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
                                  label: Text(service.name),
                                );
                              }).toList()
                                  : [const Chip(label: Text('No services'))],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (appointment.status == 'Done')
                      const Positioned(
                        right: 8,
                        top: 8,
                        child: Icon(
                          Icons.check,
                          color: Colors.orange,
                          size: 28,
                        ),
                      ),
                  ],
                ),
              );
            },
          );


          // return ListView.builder(
          //   padding: const EdgeInsets.all(8.0),
          //   itemCount: filteredAppointments.length,
          //   itemBuilder: (context, index) {
          //     Appointment appointment = filteredAppointments[index];
          //     return Padding(
          //       padding: const EdgeInsets.symmetric(vertical: 8.0),
          //       child: Container(
          //         decoration: BoxDecoration(
          //           color: Colors.white,
          //           borderRadius: BorderRadius.circular(10),
          //           boxShadow: [
          //             BoxShadow(
          //               color: Colors.grey.withOpacity(0.5),
          //               spreadRadius: 2,
          //               blurRadius: 5,
          //               offset: const Offset(0, 3),
          //             ),
          //           ],
          //         ),
          //         child: Padding(
          //           padding: const EdgeInsets.all(16.0),
          //           child: Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               Row(
          //                 children: [
          //                   Icon(Icons.calendar_today, size: 16),
          //                   const SizedBox(width: 8),
          //                   Text(
          //                     'Date: ${DateFormat('dd/MM/yy').format(appointment.date.toDate())}',
          //                     style: const TextStyle(
          //                       fontWeight: FontWeight.bold,
          //                       fontSize: 16,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //               const SizedBox(height: 8),
          //               Row(
          //                 children: [
          //                   Icon(Icons.access_time, size: 16),
          //                   const SizedBox(width: 8),
          //                   Text(
          //                     'Time: ${appointment.time}',
          //                     style: const TextStyle(
          //                       fontSize: 14,
          //                       fontWeight: FontWeight.bold,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //               const SizedBox(height: 8),
          //               Row(
          //                 children: [
          //                   Icon(Icons.person, size: 16),
          //                   const SizedBox(width: 8),
          //                   Text(
          //                     'Client Name: ${appointment.clientName ?? 'N/A'}',
          //                     style: const TextStyle(
          //                       fontSize: 14,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //               if (appointment.isHomeService) ...[
          //                 const SizedBox(height: 8),
          //                 Row(
          //                   children: [
          //                     Icon(Icons.home, size: 16),
          //                     const SizedBox(width: 8),
          //                     Text(
          //                       'Address: ${appointment.address ?? 'N/A'}',
          //                       style: const TextStyle(
          //                         fontSize: 14,
          //                       ),
          //                     ),
          //                   ],
          //                 ),
          //               ],
          //               const SizedBox(height: 8),
          //               Row(
          //                 children: [
          //                   Icon(Icons.local_shipping, size: 16),
          //                   const SizedBox(width: 8),
          //                   Text(
          //                     'Home Service: ${appointment.isHomeService ? 'Yes' : 'No'}',
          //                     style: const TextStyle(
          //                       fontSize: 14,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //               const SizedBox(height: 8),
          //               Row(
          //                 children: [
          //                   Icon(Icons.phone, size: 16),
          //                   const SizedBox(width: 8),
          //                   Text(
          //                     'Phone Number: ${appointment.phoneNumber ?? 'N/A'}',
          //                     style: const TextStyle(
          //                       fontSize: 14,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //               const SizedBox(height: 8),
          //               Row(
          //                 children: [
          //                   Icon(Icons.attach_money, size: 16),
          //                   const SizedBox(width: 8),
          //                   Text(
          //                     'Total Price: ${appointment.totalPrice.toStringAsFixed(2)}',
          //                     style: const TextStyle(
          //                       fontSize: 14,
          //                       fontWeight: FontWeight.bold,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //               const SizedBox(height: 8),
          //               Wrap(
          //                 spacing: 8,
          //                 children: appointment.services.isNotEmpty
          //                     ? appointment.services.map((service) {
          //                   return Chip(
          //                     label: Text(service.name ?? 'Unknown'),
          //                   );
          //                 }).toList()
          //                     : [const Chip(label: Text('No services'))],
          //               ),
          //               ],
          //           ),
          //         ),
          //       ),
          //     );
          //   },
          // );
        }
      },
    );
  }

  // List<Appointment> _filterAppointmentsForToday(List<Appointment> appointments) {
  //   DateTime now = DateTime.now();
  //   return appointments.where((appointment) {
  //     DateTime appointmentDate = appointment.date.toDate();
  //     return appointmentDate.year == now.year &&
  //         appointmentDate.month == now.month &&
  //         appointmentDate.day == now.day &&
  //         appointment.status != 'Done';
  //   }).toList();
  // }
  //
  // List<Appointment> _filterAppointmentsForUpcoming(List<Appointment> appointments) {
  //   DateTime now = DateTime.now();
  //   return appointments.where((appointment) {
  //     DateTime appointmentDate = appointment.date.toDate();
  //     return appointmentDate.isAfter(now) && appointment.status != 'Done';
  //   }).toList();
  // }
  //
  // List<Appointment> _filterAppointmentsForHistory(List<Appointment> appointments) {
  //   DateTime now = DateTime.now();
  //   return appointments.where((appointment) {
  //     DateTime appointmentDate = appointment.date.toDate();
  //     return (appointmentDate.isBefore(now) &&
  //         (appointment.status == 'Done' || appointment.status == 'Cancelled') &&
  //         appointmentDate.day != now.day);
  //   }).toList();
  // }

  List<Appointment> _filterAppointmentsForToday(
      List<Appointment> appointments) {
    DateTime now = DateTime.now();
    return appointments.where((appointment) {
      DateTime appointmentDate = _createDateTime(
          appointment.date.toDate(), appointment.time);
      return appointmentDate.year == now.year &&
          appointmentDate.month == now.month &&
          appointmentDate.day == now.day &&
          appointment.status != 'Done'; // Ensure 'Done' appointments are excluded
    }).toList();
  }


  List<Appointment> _filterAppointmentsForUpcoming(
      List<Appointment> appointments) {
    DateTime now = DateTime.now();
    return appointments.where((appointment) {
      DateTime appointmentDate = _createDateTime(
          appointment.date.toDate(), appointment.time);
      return appointmentDate.isAfter(now) && appointment.status != 'Done';
    }).toList();
  }

  List<Appointment> _filterAppointmentsForHistory(
      List<Appointment> appointments) {
    DateTime now = DateTime.now();
    return appointments.where((appointment) {
      DateTime appointmentDate = appointment.date.toDate();
      // Include only appointments marked as "Done" or those in the past not marked as "Confirmed"
      return (appointmentDate.isBefore(now) &&
          appointment.status != 'Confirmed' &&
          appointmentDate.day != now.day) ||
          appointment.status == 'Done';
    }).toList();
  }

  DateTime _createDateTime(DateTime date, String time) {
    try {
      // Remove AM/PM and trim the time string
      String cleanedTime = time.replaceAll(RegExp(r'(AM|PM)'), '').trim();
      List<String> timeParts = cleanedTime.split(':');
      if (timeParts.length != 2) {
        throw const FormatException('Invalid time format');
      }

      int hour = int.parse(timeParts[0].trim());
      int minute = int.parse(timeParts[1].trim());

      // Handle AM/PM
      if (time.contains('PM') && hour < 12) {
        hour += 12;
      }
      if (time.contains('AM') && hour == 12) {
        hour = 0;
      }

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      log('Error parsing time: $e');
      // Return a default DateTime or handle the error appropriately
      return DateTime(date.year, date.month, date.day);
    }
  }
}
