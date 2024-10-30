import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:online_barber_app/controllers/appointment_controller.dart';
import 'package:online_barber_app/models/appointment_model.dart';
import 'package:online_barber_app/models/service_model.dart';
import 'package:online_barber_app/push_notification_service.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:online_barber_app/views/user/home_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../utils/cutom_google_map.dart';
import 'package:http/http.dart' as http;

class BookAppointment extends StatefulWidget {
  final List<Service> selectedServices;
  final String uid;
  final String barberId;
  final String barberName;
  final String barberAddress;

  const BookAppointment({
    super.key,
    required this.selectedServices,
    required this.uid,
    required this.barberId,
    required this.barberName,
    required this.barberAddress,
  });

  @override
  State<BookAppointment> createState() => _BookAppointmentState();
}

  class _BookAppointmentState extends State<BookAppointment> {
    final AppointmentController _appointmentController = AppointmentController();
    final TextEditingController _addressController = TextEditingController();
    final TextEditingController _phoneNumberController = TextEditingController();
    final TextEditingController _timeController = TextEditingController();
    final TextEditingController _homeServicePriceController = TextEditingController();
    DateTime selectedDay = DateTime.now();
    DateTime focusedDay = DateTime.now();
    bool isBooking = false;
    String _userName = '';
    bool _isHomeService = false;
    String _selectedPaymentMethod = 'Cash'; // Default payment method
    List<ProductDetails> _products = [];
    final InAppPurchase _iap = InAppPurchase.instance;
    bool _available = true;

    @override
    void initState() {
      super.initState();
      _phoneNumberController.addListener(_onPhoneNumberChanged);
      _getPhoneNumber();
      _getUserName();
      _initializeHomeServicePrice();
      _initializeInAppPurchase();
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

    Future<void> _initializeInAppPurchase() async {
      final bool available = await _iap.isAvailable();
      setState(() {
        _available = available;
      });
      if (_available) {
        await _loadProducts();
        _handlePurchaseUpdates();
      }
    }

    Future<void> _loadProducts() async {
      // Create a set to store product IDs dynamically from selected services
      Set<String> _serviceProductIds = widget.selectedServices.map((service) {
        // Assuming each service has a corresponding product ID in the app store
        return service
            .productId; // Ensure your Service model has a 'productId' field
      }).toSet();

      // Query the product details using the service product IDs
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(_serviceProductIds);

      if (response.notFoundIDs.isNotEmpty) {
        log('Error: Some product IDs not found - ${response.notFoundIDs}');
      }

      setState(() {
        _products = response.productDetails;
      });
    }

    void _handlePurchaseUpdates() {
      final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
      purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
        for (var purchase in purchaseDetailsList) {
          if (purchase.status == PurchaseStatus.purchased) {
            _completeAppointment(); // Call method to complete the appointment after purchase
          } else if (purchase.status == PurchaseStatus.error) {
            _showErrorDialog(purchase.error?.message ?? "Purchase error");
          }
        }
      });
    }

    Future<void> _purchaseService(ProductDetails product) async {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      _iap.buyConsumable(purchaseParam: purchaseParam); // Initiating the purchase
    }

    void _onPhoneNumberChanged() {
      setState(() {});
    }

    Future<void> _getPhoneNumber() async {
      try {
        DocumentSnapshot<Map<String, dynamic>> document = await FirebaseFirestore
            .instance
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
        DocumentSnapshot<Map<String, dynamic>> document = await FirebaseFirestore
            .instance
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
        for (var service in widget.selectedServices) {
          final servicePrices = service.barberPrices ?? [];
          for (var priceInfo in servicePrices) {
            if (priceInfo['barberId'] == widget.barberId &&
                priceInfo['isHomeService'] == true) {
              homeServicePrice =
                  double.tryParse(priceInfo['price'].toString()) ?? 0.0;
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
      // Check for necessary inputs
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
        // Check if any service requires in-app purchase
        if (_products.isNotEmpty) {
          // Assuming the first product matches the selected service
          final ProductDetails product = _products.first; // Adjust this as needed

          // Initiate in-app purchase
          await _purchaseService(product);
          // The rest of the booking process will continue after successful payment
        } else {
          // If no IAP is needed, proceed with appointment booking
          await _completeAppointment(); // Proceed to complete booking
        }

      } catch (e) {
        _showErrorDialog(e.toString());
      } finally {
        setState(() {
          isBooking = false;
        });
      }
    }



    Future<void> _completeAppointment() async {
      try {
        String id = FirebaseFirestore.instance.collection('appointments').doc().id;
        Timestamp timestamp = Timestamp.fromDate(selectedDay);

        // Fetch client and barber documents
        DocumentSnapshot clientDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .get();
        DocumentSnapshot barberDoc = await FirebaseFirestore.instance
            .collection('barbers')
            .doc(widget.barberId)
            .get();

        // Calculate total price for the appointment
        double totalPrice = _calculateTotalPrice();

        // Create appointment object
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
          homeServicePrice: _isHomeService
              ? double.parse(_homeServicePriceController.text)
              : 0.0,
          totalPrice: totalPrice,
        );

        // Book the appointment in Firestore
        await _appointmentController.bookAppointment(appointment);

        // Prepare notification message with barber name
        String services = widget.selectedServices.map((s) => s.name).join(', ');
        String notificationBody = '''
      New Appointment Booked!
      Client: $_userName
      Barber: ${widget.barberName}
      Date: ${selectedDay.toLocal().toString().split(' ')[0]}
      Time: ${_timeController.text}
      Address: ${_isHomeService ? _addressController.text : widget.barberAddress}
      Phone: ${_phoneNumberController.text}
      Services: $services
      Home Service: $_isHomeService
      Total Price: ${totalPrice.toStringAsFixed(2)}
    ''';

        // Send notification to the barber
        final String barberDeviceToken = await getBarberDeviceToken(widget.barberId);
        await PushNotificationService.sendNotification(
          barberDeviceToken,
          context,
          'You have a new appointment booked!',
          notificationBody,
        );

        // Send Email Notification with barber name
        await _sendEmailNotification(notificationBody);

        // Show success dialog
        _showSuccessDialog();
      } catch (e) {
        _showErrorDialog(e.toString());
      }
    }

// Function to send an email notification
    Future<void> _sendEmailNotification(String notificationBody) async {
      final smtpServer = gmail('oakmate1206@gmail.com', 'tmzlvintkyvpindv');

      final message = Message()
        ..from = Address('ios.cypersol@gmail.com', 'Online Barber')
        ..recipients.add('oakmate1206@gmail.com') // Recipient's email address
        ..subject = 'New Appointment Booked!'
        ..text = notificationBody;

      try {
        final sendReport = await send(message, smtpServer);
        print('Email sent: ' + sendReport.toString());
      } on MailerException catch (e) {
        print('Email not sent. \n' + e.toString());
      }
    }

// Function to send an email notification
//     Future<void> _sendEmailNotification(String notificationBody) async {
//       final smtpServer = gmail('oakmate1206@gmail.com', 'tmzlvintkyvpindv');
//
//       final message = Message()
//         ..from = Address('ios.cypersol@gmail.com', 'Online Barber')
//         ..recipients.add('oakmate1206@gmail.com') // Recipient's email address
//         ..subject = 'New Appointment Booked!'
//         ..text = notificationBody;
//
//       try {
//         final sendReport = await send(message, smtpServer);
//         print('Email sent: ' + sendReport.toString());
//       } on MailerException catch (e) {
//         print('Email not sent. \n' + e.toString());
//       }
//     }

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
        double homeServicePrice =
            double.tryParse(_homeServicePriceController.text) ?? 0.0;
        return basePrice + homeServicePrice;
      }
      return basePrice;
    }

    Future<String> getBarberDeviceToken(String barberId) async {
      try {
        DocumentSnapshot barberDoc = await FirebaseFirestore.instance
            .collection('barbers')
            .doc(barberId)
            .get();
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

    void _selectTime() async {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _timeController.text = pickedTime.format(context);
        });
      }
    }

    void _openGoogleMap() async {
      final String? result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomGoogleMap(),
        ),
      );
      if (result != null) {
        setState(() {
          _addressController.text = result;
        });
      }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Date',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TableCalendar(
                  firstDay: DateTime.utc(2010, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: selectedDay,
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) => isSameDay(selectedDay, day),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _timeController,
                  readOnly: true,
                  onTap: _selectTime,
                  decoration: InputDecoration(
                    suffixIcon: const Icon(Icons.access_time),
                    hintText: 'Select time',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Phone Number',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Home Service',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Switch(
                      value: _isHomeService,
                      onChanged: (bool value) {
                        setState(() {
                          _isHomeService = value;
                        });
                      },
                    ),
                  ],
                ),
                if (_isHomeService)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Home Service Price',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        readOnly: true,
                        controller: _homeServicePriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Home Service Price',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(color: Colors.orange),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Address',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: 'Enter address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(color: Colors.orange),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.location_on),
                            onPressed: _openGoogleMap,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'Barber: ${widget.barberName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.orange),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selected Services',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.selectedServices.length,
                  itemBuilder: (context, index) {
                    final service = widget.selectedServices[index];
                    final barberPrice = _getBarberPrice(service);
                    return ListTile(
                      title: Text(service.name),
                      subtitle:
                          Text('Price: ${barberPrice.toStringAsFixed(2)}'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (_isHomeService)
                  Text(
                    'Home Service Price: ${double.tryParse(_homeServicePriceController.text)?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Total Price: ${_calculateTotalPrice().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Payment Options Section
                const SizedBox(height: 16),
                const Text(
                  'Select Payment Method',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Cash'),
                        leading: Radio<String>(
                          value: 'Cash',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedPaymentMethod = value!;
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('Online Payment'),
                        leading: Radio<String>(
                          value: 'Online',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedPaymentMethod = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Center(
                  child: isBooking
                      ? const LoadingDots()
                      : ElevatedButton(
                          onPressed: () async {
                            if (_selectedPaymentMethod == 'Cash') {
                              await _bookAppointment();
                            } else if (_selectedPaymentMethod == 'Online') {
                              if (_products.isNotEmpty) {
                                await _purchaseService(_products.first);
                              } else {
                                _showErrorDialog(
                                    'No products available for purchase.');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('Book Appointment'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
