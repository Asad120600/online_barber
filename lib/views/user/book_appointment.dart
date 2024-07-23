import 'dart:developer';
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
  final TextEditingController _homeServicePriceController = TextEditingController();
  String _userName = '';
  bool _isHomeService = false;

  @override
  void initState() {
    super.initState();
    _phoneNumberController.addListener(_onPhoneNumberChanged);
    _getPhoneNumber();
    _getUserName();
    _initializeHomeServicePrice();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneNumberController.removeListener(_onPhoneNumberChanged);
    _phoneNumberController.dispose();
    _timeController.dispose();
    _homeServicePriceController.dispose();
    super.dispose();
  }

  void _onPhoneNumberChanged() {
    setState(() {});
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
      log('Error fetching phone number: $e');
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
      log('Error fetching user name: $e');
    }
  }

  Future<void> _initializeHomeServicePrice() async {
    double homeServicePrice = 0.0;

    try {
      // Iterate through each selected service to find the home service price
      for (var service in widget.selectedServices) {
        final servicePrices = service.barberPrices ?? [];
        for (var priceInfo in servicePrices) {
          if (priceInfo['barberId'] == widget.barberId && priceInfo['isHomeService'] == true) {
            homeServicePrice = double.tryParse(priceInfo['price'].toString()) ?? 0.0;
            break;
          }
        }
      }
      setState(() {
        _homeServicePriceController.text = homeServicePrice.toString();
      });
    } catch (e) {
      log('Error fetching home service price: $e');
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
    if (_isHomeService && _addressController.text.isEmpty) {
      _showErrorDialog('Address cannot be empty for home service');
      return;
    }
    if (_phoneNumberController.text.isEmpty) {
      _showErrorDialog('Phone number cannot be empty');
      return;
    }
    if (_isHomeService) {
      try {
        double.parse(_homeServicePriceController.text);
      } catch (e) {
        _showErrorDialog('Invalid home service price');
        return;
      }
    }

    setState(() {
      isBooking = true;
    });

    try {
      String id = FirebaseFirestore.instance.collection('appointments').doc().id;
      Timestamp timestamp = Timestamp.fromDate(selectedDay);

      DocumentSnapshot clientDoc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      DocumentSnapshot barberDoc = await FirebaseFirestore.instance.collection('barbers').doc(widget.barberId).get();

      // Calculate total price
      double totalPrice = _calculateTotalPrice();

      final appointment = Appointment(
        id: DateTime.now().toIso8601String(),
        date: timestamp,
        time: _timeController.text,
        services: widget.selectedServices,
        address: _isHomeService ? _addressController.text : widget.barberAddress,
        phoneNumber: _phoneNumberController.text,
        uid: widget.uid,
        barberName: widget.barberName,
        barberAddress: widget.barberAddress,
        clientName: _userName,
        barberId: widget.barberId,
        isHomeService: _isHomeService,
        homeServicePrice: _isHomeService ? double.parse(_homeServicePriceController.text) : 0.0,
        totalPrice: totalPrice,
      );

      await _appointmentController.bookAppointment(appointment);

      String services = widget.selectedServices.map((s) => s.name).join(', ');
      String notificationBody = '''
New Appointment Booked!
Client: $_userName
Date: ${selectedDay.toLocal().toString().split(' ')[0]}
Time: ${_timeController.text}
Address: ${_isHomeService ? _addressController.text : widget.barberAddress}
Phone: ${_phoneNumberController.text}
Services: $services
Home Service: $_isHomeService
Total Price: ${totalPrice.toStringAsFixed(2)}
''';

      final String barberDeviceToken = await getBarberDeviceToken(widget.barberId);
      await PushNotificationService.sendNotification(
        barberDeviceToken,
        context,
        'You have a new appointment booked!',
        notificationBody,
      );
      log(barberDeviceToken);

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
      log('Error fetching barber device token: $e');
      rethrow;
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
                    (Route<dynamic> route) => false,
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

  double _getBarberPrice(Service service) {
    for (var priceInfo in service.barberPrices ?? []) {
      if (priceInfo['barberId'] == widget.barberId) {
        return double.tryParse(priceInfo['price'].toString()) ?? service.price;
      }
    }
    return service.price;
  }

  double _calculateTotalPrice() {
    double basePrice = widget.selectedServices.fold(0.0, (total, service) {
      return total + _getBarberPrice(service);
    });

    if (_isHomeService) {
      double homeServicePrice = double.tryParse(_homeServicePriceController.text) ?? 0.0;
      return basePrice + homeServicePrice;
    } else {
      return basePrice;
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = _calculateTotalPrice();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selected Services',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                itemCount: widget.selectedServices.length,
                itemBuilder: (context, index) {
                  final service = widget.selectedServices[index];
                  double barberPrice = _getBarberPrice(service);
                  return ListTile(
                    title: Text(service.name),
                    trailing: Text(
                      barberPrice.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              TableCalendar(
                focusedDay: focusedDay,
                firstDay: DateTime.now(),
                lastDay: DateTime(2100),
                selectedDayPredicate: (day) {
                  return isSameDay(selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    this.selectedDay = selectedDay;
                    this.focusedDay = focusedDay;
                  });
                },
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: 'Time Slot',
                  hintText: 'Select time slot',
                  suffixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                readOnly: true,
                onTap: () {
                  showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  ).then((selectedTime) {
                    if (selectedTime != null) {
                      setState(() {
                        _timeController.text = selectedTime.format(context);
                      });
                    }
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Home Service'),
                  Switch(
                    value: _isHomeService,
                    onChanged: (value) {
                      setState(() {
                        _isHomeService = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isHomeService)
                Column(
                  children: [
                    TextField(
                      controller: _homeServicePriceController,
                      decoration: InputDecoration(
                        labelText: 'Home Service Price',
                        hintText: 'Enter price for home service',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Home Service Address',
                        hintText: 'Enter your address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              Text(
                'Total Price: ${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              isBooking
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                    child: Button(
                                    child: Text('Book Appointment'),
                                    onPressed: _bookAppointment,
                                  ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
