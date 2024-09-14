import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:online_barber_app/controllers/appointment_controller.dart';
import 'package:online_barber_app/models/appointment_model.dart';
import 'package:online_barber_app/models/notification_model.dart';
import 'package:online_barber_app/push_notification_service.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:online_barber_app/views/barber/barber_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class BarberPanel extends StatefulWidget {
  final String barberId;
  const BarberPanel({super.key, required this.barberId});

  @override
  State<BarberPanel> createState() => _BarberPanelState();
}

class _BarberPanelState extends State<BarberPanel> with SingleTickerProviderStateMixin {
  late final AppointmentController _appointmentController;
  TabController? _tabController;
  bool _showSnackBar = false;

  @override
  void initState() {
    super.initState();
    // _showProfileIncompleteSnackBar();
    _appointmentController = AppointmentController();
    _tabController = TabController(length: 3, vsync: this);

    _checkBarberProfile();
  }

  Future<void> _checkBarberProfile() async {
    try {
      DocumentSnapshot barberDoc = await FirebaseFirestore.instance.collection('barbers').doc(widget.barberId).get();
      if (barberDoc.exists) {
        final data = barberDoc.data() as Map<String, dynamic>;
        final address = data['address'] as String?;
        final shopName = data['shopName'] as String?;

        // Show snackbar if address or shopName is missing
        if (address == null || address.isEmpty || shopName == null || shopName.isEmpty) {
          // Trigger UI update to show Snackbar
          setState(() {
            _showSnackBar = true;
          });

          // Use addPostFrameCallback to ensure Snackbar is shown after the frame is built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please update your Address and Shop Name in profile settings.'),
                duration: Duration(seconds: 5),
              ),
            );
          });
        }
      }
    } catch (e) {
      log('Error fetching barber profile: $e');
    }
  }

  void _showProfileIncompleteSnackBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please update your Address and Shop Name in profile settings.'),
          duration: Duration(seconds: 5),
        ),
      );
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<String> getUserDeviceToken(String uid) async {
  try {
    DocumentSnapshot barberDoc = await FirebaseFirestore.instance.collection(
        'users').doc(uid).get();
    if (barberDoc.exists) {
      final data = barberDoc.data() as Map<String, dynamic>;
      final deviceToken = data['token'];
      if (deviceToken != null) {
        return deviceToken;
      } else {
        throw Exception('Device token is missing in the document');
      }
    } else {
      throw Exception('Barber document does not exist');
    }
  } catch (e) {
    log('Error fetching barber device token: $e');
    rethrow;
  }
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


  Widget _buildAppointmentsTab(
      List<Appointment> Function(List<Appointment>) filterFunction,
      String tabType) {
    return RefreshIndicator(
        onRefresh: () async {
      // Force a rebuild by calling setState
      setState(() {});
    },
    child : StreamBuilder<List<Appointment>>(
      stream: _appointmentController.getAppointmentsByBarberID(widget.barberId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center( child: LoadingDots( ),);
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
              bool isToday = tabType == 'Today';

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
                              Expanded(
                                child: Text(
                                  'Address: ${appointment.address}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                  maxLines: 2, // Allow the text to wrap to a second line if needed
                                  overflow: TextOverflow.ellipsis, // Show ellipsis if the text overflows two lines
                                  softWrap: true, // Enable wrapping at soft line breaks
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(appointment.address)}';
                                  if (await canLaunch(url)) {
                                    await launch(url);
                                  } else {
                                    throw 'Could not launch $url';
                                  }
                                },
                                icon: const Icon(Icons.pin_drop_outlined),
                              ),
                            ],
                          )

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
                        const SizedBox(height: 8),
                        if (isToday) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (appointment.status != 'Confirmed')
                                Button(
                                  width: 120,
                                  onPressed: () => _confirmAppointment(appointment),
                                  child: const Text('Confirm'),
                                ),
                              if (appointment.status == 'Confirmed' && appointment.status != 'Done')
                                Button(
                                  width: 120,
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
    )
    );
  }

  void _updateStatusAndMoveToHistory(String appointmentId, String status) async {
    try {
      await _appointmentController.updateAppointmentStatus(appointmentId, status);
    } catch (e) {
      log('Error updating status: $e');
    }
  }

  void _confirmAppointment(Appointment appointment) async {
    try {
      await _appointmentController.updateAppointmentStatus(
          appointment.id, 'Confirmed');

      // Fetch the user ID from the appointment
      String userId = appointment.uid; // Handle potential null UID

      // Create a notification
      NotificationModel notification = NotificationModel(
        id: '', // Firestore will generate the ID
        title: 'Appointment Confirmed',
        body: 'Your appointment on ${DateFormat('dd/MM/yyyy').format(
            appointment.date.toDate())} at ${appointment
            .time} has been confirmed.',
        date: DateTime.now(), // Current date and time
      );

      // Save notification to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification.toMap());

      // Fetch the device token
      String deviceToken = await getUserDeviceToken(userId);

      // Send notification to the user
      await PushNotificationService.sendNotification(
          deviceToken, context, notification.title, notification.body);

      setState(() {}); // Refresh the UI
    } catch (e) {
      log('Error confirming appointment: $e');
    }
  }

  DateTime _createDateTime(DateTime date, String time) {
    try {
      // Define the input format for time strings (e.g., "09 AM" or "09:00 AM")
      final timeFormat = DateFormat('hh:mm a');
      // Parse the time string to a DateTime object
      final timeOfDay = timeFormat.parse(time);
      // Combine the date and time components
      return DateTime(
          date.year, date.month, date.day, timeOfDay.hour, timeOfDay.minute);
    } catch (e) {
      log('Error parsing time: $e');
      // Return a default date-time in case of error
      return DateTime(date.year, date.month, date.day);
    }
  }

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
}



