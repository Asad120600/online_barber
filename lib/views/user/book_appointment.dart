import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:online_barber_app/controllers/appointment_controller.dart';
import 'package:online_barber_app/models/appointment_model.dart';
import 'package:online_barber_app/models/service_model.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/utils/button.dart'; // Adjusted import for Button widget

class BookAppointment extends StatefulWidget {
  final List<Service> selectedServices;
  final String uid;

  const BookAppointment({
    Key? key,
    required this.selectedServices,
    required this.uid,
  }) : super(key: key);

  @override
  _BookAppointmentState createState() => _BookAppointmentState();
}

class _BookAppointmentState extends State<BookAppointment> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Service> _selectedServices = [];
  List<String> _predictions = [];

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedServices = widget.selectedServices;
    _addressController.addListener(_onAddressChanged);
    _phoneNumberController.addListener(_onPhoneNumberChanged);
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();
    _phoneNumberController.removeListener(_onPhoneNumberChanged);
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _onAddressChanged() {
    if (_addressController.text.isNotEmpty) {
      _getPlacePredictions(_addressController.text);
    } else {
      setState(() {
        _predictions = [];
      });
    }
  }

  void _onPhoneNumberChanged() {
    setState(() {
      // No specific action needed here, just to refresh UI if needed
    });
  }

  Future<void> _getPlacePredictions(String input) async {
    // Simulated prediction data for demo purposes
    List<String> predictions = [
      'Address 1',
      'Address 2',
    ];

    setState(() {
      _predictions = predictions;
    });
  }

  Future<void> _openGoogleMapsPopup() async {
    // Simulated location selection for demo purposes
    LatLng selectedLocation = const LatLng(37.4219999, -122.0840575);
    _addressController.text =
        'Selected Location: ${selectedLocation.latitude}, ${selectedLocation.longitude}';
    FocusScope.of(context).unfocus(); // Hide keyboard
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
              itemCount: _selectedServices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _selectedServices[index].name,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    'Price: ${_selectedServices[index].price}',
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
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
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
              controller: timeController,
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
                focusColor: Colors.black,
                hintStyle: const TextStyle(
                  color: Color(0xFF828A89),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(
                  Icons.watch_later,
                  color: Colors.black,
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.black,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(16),
                  ),
                ),
              ),
              onTap: () async {
                TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) {
                  setState(() {
                    timeController.text = picked.format(context);
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter Your Address',
              style: TextStyle(
                fontFamily: 'Acumin Pro',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: _openGoogleMapsPopup,
                ),
              ],
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
              decoration: const InputDecoration(
                hintText: 'Enter your phone number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_predictions.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Predictions',
                style: TextStyle(
                  fontFamily: 'Acumin Pro',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._predictions.map((prediction) => ListTile(
                    title: Text(
                      prediction,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      _addressController.text = prediction;
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _predictions = [];
                      });
                    },
                  )),
            ],
            const SizedBox(height: 16),
            Center(
              child: Button(
                onPressed: () async {
                  DocumentSnapshot<Map<String, dynamic>> document =
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .get();
                  final data = document.data()!;
                  String userName = data['firstName'];
                  try {
                    if (_selectedDay == null || timeController.text.isEmpty) {
                      throw Exception('Please select a date and time slot');
                    }
                    if (_addressController.text.isEmpty) {
                      throw Exception('Address cannot be empty');
                    }
                    if (_phoneNumberController.text.isEmpty) {
                      throw Exception('Phone number cannot be empty');
                    }

                    // Create and save the appointment
                    final appointment = Appointment(
                      id: DateTime.now().toString(),
                      date: _selectedDay!,
                      services: _selectedServices,
                      address: _addressController.text,
                      phoneNumber: _phoneNumberController.text,
                      uid: LocalStorage.getUserID().toString(),
                      time: timeController.text,
                      clientName: userName,
                    );

                    await AppointmentController().bookAppointment(appointment);
                    Navigator.pop(context, 'Appointment booked successfully');

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Success'),
                        content: const Text('Appointment booked successfully!'),
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
                child: const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
