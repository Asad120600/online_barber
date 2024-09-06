import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:online_barber_app/controllers/appointment_controller.dart';
import 'package:online_barber_app/models/appointment_model.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:online_barber_app/views/admin/admin_drawer.dart';
import 'package:online_barber_app/views/admin/admin_shop/order_notifications.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  late final AppointmentController _appointmentController;
  int _notificationCount = 0;


  @override
  void initState() {
    super.initState();
    _appointmentController = AppointmentController();
    _updateNotificationCount();

  }
  void _updateNotificationCount() {
    setState(() {
      _notificationCount++;
    });
  }

  void _resetNotificationCount() {
    setState(() {
      _notificationCount = 0;
    });
  }

  Future<String> _getUserName(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['name'] ?? 'Unknown User';
      }
    } catch (e) {
      log('Error fetching user name: $e');
    }
    return 'Unknown User';
  }

  Future<void> _refreshAppointments() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Panel'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {
                  _resetNotificationCount(); // Reset the counter
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminNotificationsPage(),
                    ),
                  );
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        '$_notificationCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: AdminDrawer(screenWidth: screenWidth),
      body: RefreshIndicator(
        onRefresh: _refreshAppointments,
        child: StreamBuilder<List<Appointment>>(
          stream: _appointmentController.getAllAppointments(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: LoadingDots(),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No Appointments found.'));
            } else {
              List<Appointment> appointments = snapshot.data!;

              appointments.sort((a, b) {
                int dateComparison = a.date.compareTo(b.date);
                if (dateComparison != 0) return dateComparison;
                return a.time.compareTo(b.time);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  Appointment appointment = appointments[index];

                  return FutureBuilder<String>(
                    future: _getUserName(appointment.uid),
                    builder: (context, userNameSnapshot) {
                      if (userNameSnapshot.hasError) {
                        return Center(child: Text('Error: ${userNameSnapshot.error}'));
                      } else {
                        String userName = userNameSnapshot.data ?? 'Unknown User';

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
                                          const Icon(Icons.person, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Name: ${appointment.clientName}',
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
                                          const Icon(Icons.calendar_today, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Date: ${appointment.date != null ? DateFormat.yMd().format(appointment.date.toDate()) : 'N/A'}',
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
                                          const Icon(Icons.cut, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Barber: ${appointment.barberName}',
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
                                            label: Text(service.name ?? 'Unknown Service'),
                                          );
                                        }).toList()
                                            : [const Chip(label: Text('No services'))],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ),
                              if (appointment.status == 'Done')
                                const Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.orange,
                                    size: 35,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }
                    },
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
