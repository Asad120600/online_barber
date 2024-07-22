/// notify
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/controllers/appointment_controller.dart';
import 'package:online_barber_app/models/appointment_model.dart';
import 'package:online_barber_app/models/service_model.dart';
import 'package:online_barber_app/push_notification_service.dart';
import 'package:online_barber_app/views/user/home_screen.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:table_calendar/table_calendar.dart';

class BookAppointment extends StatefulWidget {
  final List<Service> selectedServices;
  final String uid;
  final String barberId;
  final String barberName;
  final String barberAddress;

  const BookAppointment({
    Key? key,
    required this.selectedServices,
    required this.uid,
    required this.barberId,
    required this.barberName,
    required this.barberAddress,
  }) : super(key: key);

  @override
  State<BookAppointment> createState() => _BookAppointmentState();
}

class _BookAppointmentState extends State<BookAppointment> {
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();
  bool isBooking = false;
  final AppointmentController _appointmentController = AppointmentController();

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _phoneNumberController.addListener(_onPhoneNumberChanged);
    _getPhoneNumber();
    _getUserName();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneNumberController.removeListener(_onPhoneNumberChanged);
    _phoneNumberController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _onPhoneNumberChanged() {
    setState(() {
      // Refresh UI if needed
    });
  }

  Future<void> _getPhoneNumber() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> document = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      final data = document.data()!;
      setState(() {
        _phoneNumberController.text = data['phone'] ?? '';
      });
    } catch (e) {
      print('Error fetching phone number: $e');
    }
  }


  Future<void> _getUserName() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> document = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      final data = document.data()!;
      setState(() {
        _userName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}';
      });
    } catch (e) {
      print('Error fetching user name: $e');
    }
  }

  Future<void> _bookAppointment() async {
    if (selectedDay == null) {
      _showErrorDialog('Please select a date');
      return;
    }
    if (_timeController.text.isEmpty) {
      _showErrorDialog('Please select a time slot');
      return;
    }
    if (_addressController.text.isEmpty) {
      _showErrorDialog('Address cannot be empty');
      return;
    }
    if (_phoneNumberController.text.isEmpty) {
      _showErrorDialog('Phone number cannot be empty');
      return;
    }

    setState(() {
      isBooking = true;
    });

    try {
      String id = FirebaseFirestore.instance.collection('appointments').doc().id;
      Timestamp timestamp = Timestamp.fromDate(selectedDay);

      DocumentSnapshot clientDoc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      DocumentSnapshot barberDoc = await FirebaseFirestore.instance.collection('barbers').doc(widget.barberId).get();

      final appointment = Appointment(
        id: DateTime.now().toIso8601String(),
        date: timestamp,
        time: _timeController.text,
        services: widget.selectedServices,
        address: _addressController.text,
        phoneNumber: _phoneNumberController.text,
        uid: widget.uid,
        barberName: widget.barberName,
        barberAddress: widget.barberAddress,
        clientName: _userName,
        barberId: widget.barberId,
      );

      await _appointmentController.bookAppointment(appointment);

      // Send push notification
      final String barberDeviceToken = await getBarberDeviceToken(widget.barberId);
      await PushNotificationService.sendNotification(
        barberDeviceToken,
        context,
        'You have a new appointment booked!',
      );
      print(barberDeviceToken);

      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        isBooking = false;
      });
    }
  }

  Future<String> getBarberDeviceToken(String barberId) async {
    try {
      DocumentSnapshot barberDoc = await FirebaseFirestore.instance.collection('barbers').doc(barberId).get();
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
      print('Error fetching barber device token: $e');
      rethrow; // Propagate the error to be handled in the calling function
    }
  }


  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Appointment booked successfully'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (Route<dynamic> route) => false, // Remove all previous routes
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: isBooking
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              itemCount: widget.selectedServices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    widget.selectedServices[index].name,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TableCalendar(
              focusedDay: focusedDay,
              firstDay: DateTime.utc(2020, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              selectedDayPredicate: (day) {
                return isSameDay(selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  this.selectedDay = selectedDay;
                  this.focusedDay = focusedDay;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Time Slot',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _timeController,
              readOnly: true,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.width * 0.030,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.black45,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.black,
                  ),
                ),
                hintText: "Select a time",
                hintStyle: const TextStyle(
                  color: Color(0xFF828A89),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(
                  Icons.watch_later,
                  color: Colors.orange,
                ),
              ),
              onTap: () async {
                TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) {
                  setState(() {
                    _timeController.text = picked.format(context);
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'Enter your address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Enter your phone number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.phone,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Button(
                onPressed: _bookAppointment,
                child: const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
