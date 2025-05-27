import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:online_barber_app/models/service_model.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/admin/announcement_screen_send.dart';
import 'package:online_barber_app/views/auth/login_screen.dart';
import 'package:online_barber_app/views/barber/barber_profile.dart';
import 'package:online_barber_app/views/barber/barber_stats.dart';
import 'package:online_barber_app/views/barber/set_price.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BarberDrawer extends StatefulWidget {
  const BarberDrawer({super.key, required this.screenWidth});

  final double screenWidth;

  @override
  State<BarberDrawer> createState() => _BarberDrawerState();
}

class _BarberDrawerState extends State<BarberDrawer> {
  User? _currentUser;
  String? _firstName;
  String? _imageUrl;

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
            _imageUrl = snapshot['imageUrl'];
          });
        }
      } catch (e) {
        print('Error fetching barber data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!; // Get localized strings

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
                  Flexible(
                    child: Text(
                      localizations.hello(_firstName ?? localizations.defaultName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(localizations.profile),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Use addPostFrameCallback to ensure navigation happens after the current frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BarberProfile(),
                    ),
                  );
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.price_change),
              title: Text(localizations.setPrices),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Use addPostFrameCallback to ensure navigation happens after the current frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SetServicePrices(
                        service: Service(
                          id: '',
                          name: '',
                          price: 0.0,
                          category: 'Hair Styles',
                          imageUrl: null,
                          barberPrices: null,
                          isHomeService: false,
                          homeServicePrice: 0.0,
                          productId: '',
                        ),
                        barberId: '',
                      ),
                    ),
                  );
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.query_stats_sharp),
              title: Text(localizations.stats),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Use addPostFrameCallback to ensure navigation happens after the current frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Stats(barberId: LocalStorage.getBarberId().toString()),
                    ),
                  );
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign),
              title: Text(localizations.makeAnnouncement),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Use addPostFrameCallback to ensure navigation happens after the current frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnnouncementScreen(),
                    ),
                  );
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(localizations.signOut),
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(localizations.confirmSignOut),
                      content: Text(localizations.signOutConfirmation),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(localizations.cancel),
                        ),
                        TextButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            Navigator.of(context).pop();
                            // Ensure navigation happens after the current frame
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            });
                          },
                          child: Text(localizations.signOutButton),
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
