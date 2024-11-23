import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:online_barber_app/controllers/appointment_controller.dart';
import 'package:online_barber_app/controllers/language_change_controller.dart';
import 'package:online_barber_app/models/appointment_model.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:online_barber_app/views/admin/admin_drawer.dart';
import 'package:online_barber_app/views/admin/admin_shop/order_notifications.dart';
import 'package:online_barber_app/views/user/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  late final AppointmentController _appointmentController;
  int _notificationCount = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _appointmentController = AppointmentController();
    _loadNotificationCount();
    _updateNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationCount = prefs.getInt('notificationCount') ?? 0;
    });
  }

  Future<void> _saveNotificationCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationCount', _notificationCount);
  }

  void _updateNotificationCount() {
    setState(() {
      _notificationCount++;
    });
    _saveNotificationCount();
  }

  void _resetNotificationCount() {
    setState(() {
      _notificationCount = 0;
    });
    _saveNotificationCount();
  }

  Future<String> _getUserName(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['name'] ?? AppLocalizations.of(context)!.name_e("Unknown");
      }
    } catch (e) {
      return AppLocalizations.of(context)!.name_e("Unknown");
    }
    return AppLocalizations.of(context)!.name_e("Unknown");
  }

  Future<void> _refreshAppointments() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(localizations.admin_panel),
        actions: [

          // Consumer<LanguageChangeController>(
          //   builder: (context, provider, child) {
          //     return PopupMenuButton(
          //       onSelected: (Language item) {
          //         provider.changeLanguage(
          //             item.name == localizations.english ? Locale("en") : Locale("ur"));
          //       },
          //       itemBuilder: (BuildContext context) => <PopupMenuEntry<Language>>[
          //         PopupMenuItem(value: Language.english, child: Text(localizations.english)),
          //         PopupMenuItem(value: Language.urdu, child: Text(localizations.urdu))
          //       ],
          //     );
          //   },
          // ),

          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminNotificationsPage(),
                    ),
                  );
                  _resetNotificationCount();
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Center(
                      child: Text(
                        '$_notificationCount',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            icon: const Icon(Icons.menu),
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
              return const Center(child: LoadingDots());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(localizations.loading_error(snapshot.error.toString())),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(localizations.no_appointments_found));
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
                        return Center(
                          child: Text(localizations.loading_error(userNameSnapshot.error.toString())),
                        );
                      } else {
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
                                          Text(localizations.name_e(appointment.clientName)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 16),
                                          const SizedBox(width: 8),
                                          Text(localizations.date(DateFormat.yMd().format(appointment.date.toDate()))),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.cut, size: 16),
                                          const SizedBox(width: 8),
                                          Text(localizations.barber_e(appointment.barberName)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 16),
                                          const SizedBox(width: 8),
                                          Text(localizations.address_e(appointment.address)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, size: 16),
                                          const SizedBox(width: 8),
                                          Text(localizations.phone_number_e(appointment.phoneNumber)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 16),
                                          const SizedBox(width: 8),
                                          Text(localizations.time(appointment.time)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.query_stats, size: 16),
                                          const SizedBox(width: 8),
                                          Text(localizations.status(appointment.status ?? 'Unknown')),
                                        ],
                                      ),
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
