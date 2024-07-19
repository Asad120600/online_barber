import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/views/user/home_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:online_barber_app/controllers/appointment_controller.dart';
import 'package:online_barber_app/models/appointment_model.dart';
import 'package:online_barber_app/models/service_model.dart';
import 'package:online_barber_app/utils/button.dart';

class BookAppointment extends StatefulWidget {
  final List<Service> selectedServices;
  final String uid;
  final String selectedBarberName;
  final String selectedBarberAddress;
  final String selectedBarberId;

  const BookAppointment({
    super.key,
    required this.selectedServices,
    required this.uid,
    required this.selectedBarberName,
    required this.selectedBarberAddress,
    required this.selectedBarberId,
  });

  @override
  _BookAppointmentState createState() => _BookAppointmentState();
}

class _BookAppointmentState extends State<BookAppointment> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Book Appointment',
          style: TextStyle(
            fontFamily: 'Acumin Pro',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Services',
              style: TextStyle(
                fontFamily: 'Acumin Pro',
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
                  subtitle: Text(
                    'Price: ${widget.selectedServices[index].price}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Date',
              style: TextStyle(
                fontFamily: 'Acumin Pro',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime(2025, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarFormat: CalendarFormat.month,
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Time Slot',
              style: TextStyle(
                fontFamily: 'Acumin Pro',
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
                fontFamily: 'Acumin Pro',
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
                fontFamily: 'Acumin Pro',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter your phone number',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(
                  Icons.phone,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Button(
                onPressed: () async {
                  try {
                    if (_selectedDay == null) {
                      throw Exception('Please select a date');
                    }
                    if (_timeController.text.isEmpty) {
                      throw Exception('Please select a time slot');
                    }
                    if (_addressController.text.isEmpty) {
                      throw Exception('Address cannot be empty');
                    }
                    if (_phoneNumberController.text.isEmpty) {
                      throw Exception('Phone number cannot be empty');
                    }

                    // Create and save the appointment
                    final appointment = Appointment(
                      id: DateTime.now().toIso8601String(), // Use ISO8601 string for ID
                      date: Timestamp.fromDate(_selectedDay!), // Convert to Timestamp
                      services: widget.selectedServices,
                      address: _addressController.text,
                      phoneNumber: _phoneNumberController.text,
                      uid: widget.uid,
                      time: _timeController.text,
                      clientName: _userName,
                      barberName: widget.selectedBarberName,
                      barberAddress: widget.selectedBarberAddress,
                      barberId: widget.selectedBarberId,
                    );

                    await AppointmentController().bookAppointment(appointment);

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
                                MaterialPageRoute(builder: (context) => HomeScreen()),
                                    (Route<dynamic> route) => false, // Remove all previous routes
                              );
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Error'),
                        content: Text(e.toString()),
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
                },
                child: Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
