import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:online_barber_app/models/service_model.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/admin/services/service_list.dart';
import 'package:online_barber_app/views/auth/login_screen.dart';
import 'package:online_barber_app/views/barber/barber_profile.dart';
import 'package:online_barber_app/views/barber/barber_stats.dart';
import 'package:online_barber_app/views/barber/set_price.dart';


class BarberDrawer extends StatefulWidget {
  const BarberDrawer({Key? key, required this.screenWidth}) : super(key: key);

  final double screenWidth;

  @override
  State<BarberDrawer> createState() => _BarberDrawerState();
}

class _BarberDrawerState extends State<BarberDrawer> {

  User? _currentUser;
  String? _firstName;
  String? _imageUrl; // Add this variable to hold the barber's image URL

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchBarberData();
  }

  Future<void> _fetchBarberData() async {
    if (_currentUser != null) {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('barbers').doc(_currentUser!.uid).get();
        if (snapshot.exists) {
          setState(() {
            _firstName = snapshot['name'];
            _imageUrl = snapshot['imageUrl']; // Fetch image URL from Firestore
          });
        }
      } catch (e) {
        print('Error fetching barber data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.screenWidth * 0.75,
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.orange,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: _imageUrl != null
                        ? NetworkImage(_imageUrl!)
                        : _currentUser?.photoURL != null && _currentUser!.photoURL!.isNotEmpty
                        ? NetworkImage(_currentUser!.photoURL!)
                        : null,
                    child: _imageUrl == null && (_currentUser?.photoURL == null || _currentUser!.photoURL!.isEmpty)
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Hello 👋, ${_firstName ?? 'Barber'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text(
                'Profile',
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BarberProfile(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.price_change),
              title: const Text(
                'Set prices',
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetServicePrices(service: Service(
                      id: '',
                      name: '',
                      price: 0.0,
                      category: 'Hair Styles',
                      imageUrl: null,
                      barberPrices: null, isHomeService: false, homeServicePrice: 0.0,
                    ), barberId: '', ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.query_stats_sharp),
              title: const Text(
                'stats',
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Stats(barberId: LocalStorage.getBarberId().toString(),),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(
                'Sign Out',
              ),
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirm Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            Navigator.of(context).pop(); // Close the dialog
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text('Sign Out'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
