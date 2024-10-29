import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/user/Drawer%20Pages/notifications.dart';
import 'package:online_barber_app/views/user/barber_list.dart';
import '../../models/service_model.dart';
import '../../utils/button.dart';
import 'user_drawer_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Service> _hairStyles = [];
  List<Service> _beardStyles = [];
  List<bool> _checkedHairStyles = [];
  List<bool> _checkedBeardStyles = [];
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _updateNotificationCount();
    });
    _fetchServices();
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

  Future<void> _fetchServices() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('services').get();
    final allServices = querySnapshot.docs.map((doc) => Service.fromSnapshot(doc)).toList();

    setState(() {
      _hairStyles = allServices.where((service) => service.category == 'Hair Styles').toList();
      _beardStyles = allServices.where((service) => service.category == 'Beard Styles').toList();
      _checkedHairStyles = List<bool>.generate(_hairStyles.length, (index) => false);
      _checkedBeardStyles = List<bool>.generate(_beardStyles.length, (index) => false);
    });
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                imageUrl != null
                    ? Image.network(imageUrl)
                    : Image.asset('assets/img/default_image.png'), // Use a default image if none is available
                SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Online Barber",
          style: TextStyle(
            fontFamily: 'Acumin Pro',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                      builder: (context) => NotificationsScreen(uid: LocalStorage.getUserID().toString()),
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
          IconButton(
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      endDrawer: AppDrawer(screenWidth: screenWidth), // Use the drawer widget
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              'Our Services',
              style: TextStyle(
                fontFamily: 'Acumin Pro',
                fontWeight: FontWeight.bold,
                fontSize: 22.0,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                _buildCategorySection('Hair Styles', _hairStyles, _checkedHairStyles, 'assets/img/haircut1.jpeg'),
                _buildCategorySection('Beard Styles', _beardStyles, _checkedBeardStyles, 'assets/img/beard1.jpeg'),
              ],
            ),
          ),
          if (_checkedHairStyles.contains(true) || _checkedBeardStyles.contains(true))
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Button(
                onPressed: () {
                  // Filter selected services
                  List<Service> selectedServices = [];
                  for (int i = 0; i < _hairStyles.length; i++) {
                    if (_checkedHairStyles[i]) {
                      selectedServices.add(_hairStyles[i]);
                    }
                  }
                  for (int i = 0; i < _beardStyles.length; i++) {
                    if (_checkedBeardStyles[i]) {
                      selectedServices.add(_beardStyles[i]);
                    }
                  }
                  // Navigate to book appointment screen with selected services
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BarberList(selectedServices: selectedServices),
                    ),
                  );
                },
                child: const Text('Continue'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title, List<Service> services, List<bool> checked, String defaultImage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Acumin Pro',
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
            ),
          ),
        ),
        ...services.asMap().entries.map((entry) {
          int index = entry.key;
          Service service = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: GestureDetector(
                onTap: () {
                  _showFullImage(context, service.imageUrl ?? defaultImage);
                },
                child: CircleAvatar(
                  backgroundImage: service.imageUrl != null
                      ? NetworkImage(service.imageUrl!)
                      : AssetImage(defaultImage) as ImageProvider,
                  radius: 25,
                ),
              ),
              title: Text(service.name),
              subtitle: Text('Price: ${service.price.toStringAsFixed(2)}'),
              trailing: Checkbox(
                value: checked[index],
                onChanged: (bool? value) {
                  setState(() {
                    checked[index] = value ?? false;
                  });
                },
              ),
              onTap: () {
                setState(() {
                  checked[index] = !checked[index];
                });
              },
            ),
          );
        }).toList(),
      ],
    );
  }
}
