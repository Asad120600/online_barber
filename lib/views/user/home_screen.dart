import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/user/barber_list.dart';
import '../../models/service_model.dart';
import '../../utils/button.dart';
import 'user_drawer_widget.dart';
import 'book_appointment.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Service> _hairStyles = [];
  List<Service> _beardStyles = [];
  List<bool> _checkedHairStyles = [];
  List<bool> _checkedBeardStyles = [];

  @override
  void initState() {
    super.initState();
    _fetchServices();
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
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Our Services',
              style: TextStyle(
                fontFamily: 'Acumin Pro',
                fontWeight: FontWeight.bold,
                fontSize: 22.0,
              ),
            ),
          ),
          Expanded(
            child: ListView(
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
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => BookAppointment(selectedServices: selectedServices, uid: LocalStorage.getUserID().toString()),
                  //   ),
                  // );
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
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Acumin Pro',
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          itemBuilder: (context, index) {
            return Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: services[index].imageUrl != null
                        ? NetworkImage(services[index].imageUrl!)
                        : AssetImage(defaultImage) as ImageProvider,
                    radius: 25,
                  ),
                  title: Text(services[index].name),
                  subtitle: Text('Price: ${services[index].price.toStringAsFixed(2)}'),
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
                if (index < services.length - 1) const Divider(color: Colors.grey),
              ],
            );
          },
        ),
      ],
    );
  }
}
