import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:online_barber_app/controllers/appointment_controller.dart';
import 'package:online_barber_app/models/appointment_model.dart';

class BarberPanelAdmin extends StatefulWidget {
  final String barberId;
  const BarberPanelAdmin({super.key, required this.barberId});

  @override
  State<BarberPanelAdmin> createState() => _BarberPanelAdminState();
}

class _BarberPanelAdminState extends State<BarberPanelAdmin>
    with SingleTickerProviderStateMixin {
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
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back)),
          title: Text(AppLocalizations.of(context)!.barber_bookings),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)!.barber_id_missing),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back)),
        title: Text(AppLocalizations.of(context)!.barber_bookings),
        bottom: _tabController != null
            ? TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.today_bookings),
                  Tab(text: AppLocalizations.of(context)!.upcoming),
                  Tab(text: AppLocalizations.of(context)!.history),
                ],
              )
            : null,
      ),
      body: _tabController != null
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsTab(_filterAppointmentsForToday, 'Today'),
                _buildAppointmentsTab(
                    _filterAppointmentsForUpcoming, 'Upcoming'),
                _buildAppointmentsTab(_filterAppointmentsForHistory, 'History'),
              ],
            )
          : Center(
              child: Text(AppLocalizations.of(context)!.failed_initialize_tabs),
            ),
    );
  }

  Widget _buildAppointmentsTab(
      List<Appointment> Function(List<Appointment>) filterFunction,
      String tabType) {
    return StreamBuilder<List<Appointment>>(
      stream: _appointmentController.getAppointmentsByBarberID(widget.barberId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          log('Error: ${snapshot.error}');
          return Center(
            child: Text(
              '${AppLocalizations.of(context)!.error}: ${snapshot.error}',
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.no_bookings_found),
          );
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
                child: _buildAppointmentCard(context, appointment),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment) {
    return Container(
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
            _buildDetailRow(Icons.person,
                '${AppLocalizations.of(context)!.client_name}: ${appointment.clientName}'),
            if (appointment.isHomeService)
              _buildDetailRow(Icons.home,
                  '${AppLocalizations.of(context)!.address}: ${appointment.address}'),
            _buildDetailRow(Icons.local_shipping,
                '${AppLocalizations.of(context)!.home_service}: ${appointment.isHomeService ? AppLocalizations.of(context)!.yes : AppLocalizations.of(context)!.no}'),
            _buildDetailRow(Icons.phone,
                '${AppLocalizations.of(context)!.phone_number}: ${appointment.phoneNumber}'),
            _buildDetailRow(Icons.attach_money,
                '${AppLocalizations.of(context)!.total_price}: ${appointment.totalPrice.toStringAsFixed(2)}'),
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
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  List<Appointment> _filterAppointmentsForToday(
      List<Appointment> appointments) {
    DateTime now = DateTime.now();
    return appointments.where((appointment) {
      DateTime appointmentDate =
          _createDateTime(appointment.date.toDate(), appointment.time);
      return appointmentDate.year == now.year &&
          appointmentDate.month == now.month &&
          appointmentDate.day == now.day &&
          appointment.status != 'Done';
    }).toList();
  }

  List<Appointment> _filterAppointmentsForUpcoming(
      List<Appointment> appointments) {
    DateTime now = DateTime.now();
    return appointments.where((appointment) {
      DateTime appointmentDate =
          _createDateTime(appointment.date.toDate(), appointment.time);
      return appointmentDate.isAfter(now) && appointment.status != 'Done';
    }).toList();
  }

  List<Appointment> _filterAppointmentsForHistory(
      List<Appointment> appointments) {
    DateTime now = DateTime.now();
    return appointments.where((appointment) {
      DateTime appointmentDate = appointment.date.toDate();
      return (appointmentDate.isBefore(now) &&
              appointment.status != 'Confirmed' &&
              appointmentDate.day != now.day) ||
          appointment.status == 'Done';
    }).toList();
  }

  DateTime _createDateTime(DateTime date, String time) {
    try {
      String cleanedTime = time.replaceAll(RegExp(r'(AM|PM)'), '').trim();
      List<String> timeParts = cleanedTime.split(':');
      if (timeParts.length != 2) {
        throw const FormatException('Invalid time format');
      }

      int hour = int.parse(timeParts[0].trim());
      int minute = int.parse(timeParts[1].trim());

      if (time.contains('PM') && hour < 12) {
        hour += 12;
      }
      if (time.contains('AM') && hour == 12) {
        hour = 0;
      }

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      log('Error parsing time: $e');
      return DateTime(date.year, date.month, date.day);
    }
  }
}
