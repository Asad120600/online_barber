import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/admin/app_settings/faqs_settings.dart';
import 'package:online_barber_app/views/admin/app_settings/help_settings.dart';
import 'package:online_barber_app/views/admin/barber%20admin/barber_stats.dart';
import 'package:online_barber_app/views/admin/services/manage_services.dart';
import 'package:online_barber_app/views/admin/services/service_list.dart';
import 'package:online_barber_app/views/admin/slideshow/slideshow_mnage.dart';
import 'package:online_barber_app/views/auth/login_screen.dart';
import 'package:online_barber_app/views/admin/users/active_users.dart';
import 'package:online_barber_app/views/admin/users/deleted_users.dart';
import 'package:online_barber_app/views/admin/app_settings/privacy_settings.dart';
import 'package:online_barber_app/views/admin/admin_profile.dart';
import 'barber admin/barber_screen.dart';

class AdminDrawer extends StatefulWidget {
  const AdminDrawer({super.key,required this.screenWidth,});

  final double screenWidth;

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {

  User? _currentUser;
  String? _firstName;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchFirstName();
  }
  Future<void> _fetchFirstName() async {
    if (_currentUser != null) {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('admins').doc(_currentUser!.uid).get();
        if (snapshot.exists) {
          setState(() {
            _firstName = snapshot['firstName'];
          });
        }
      } catch (e) {
        print('Error fetching first name: $e');
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
                  const CircleAvatar(
                    backgroundColor: Colors.orange,
                    radius: 30,
                    child: Icon(Icons.supervisor_account, size: 50, color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hello 👋, ${_firstName ?? 'Admin'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    builder: (context) => const AdminProfile(),
                  ),
                );
              },
            ),
            ExpansionTile(
              leading: const Icon(Icons.supervised_user_circle_sharp),
              title: const Text(
                'Users',
              ),
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text('Active Users'),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>ActiveUsers()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.group_off),
                  title: const Text('Deleted Users'),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>DeletedUsers()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.content_cut),
                  title: const Text(
                    'Barbers',
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  BarberListScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.settings),
              title: const Text(
                'App Settings',
              ),
              children: <Widget>[
                ListTile(
                  title: const Text(
                    'Privacy Policy Settings',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>const PrivacySettings()));
                    // Navigate to PrivacySettings screen
                  },
                ),
                ListTile(
                  title: const Text(
                    'Slide Show Settings',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>const AdminSlideshowScreen()));
                    // Navigate to PrivacySettings screen
                  },
                ),
                ListTile(
                  title: const Text(
                    'Help Settings',
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>const HelpSettings()));
                    // Navigate to NotificationSettings screen
                  },
                ),
                ListTile(
                  title: const Text(
                    'FAQs Settings',
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>const FAQsSettings()));
                    // Navigate to FAQsSettings screen
                  },
                ),
              ],
            ),

            ExpansionTile(
              leading: const Icon(Icons.miscellaneous_services_outlined),
              title: const Text(
                'Services',
              ),
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text(
                    'Add services',
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  const ManageService(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.manage_history),
                  title: const Text(
                    'Manage services',
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  const ServiceList(),
                      ),
                    );
                  },
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.query_stats_rounded),
              title: const Text(
                'Barber Stats',
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>   BarberStatsScreen(),
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
