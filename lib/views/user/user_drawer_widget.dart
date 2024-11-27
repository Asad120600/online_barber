import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/user/Drawer%20Pages/chat_list.dart';
import 'package:online_barber_app/views/user/Drawer%20Pages/notifications.dart';
import 'package:online_barber_app/views/user/Drawer%20Pages/privacy_policy.dart';
import 'package:online_barber_app/views/user/Drawer%20Pages/profile.dart';
import 'package:online_barber_app/views/user/Drawer%20Pages/show_appointments.dart';
import 'package:online_barber_app/views/user/announcements_show.dart';
import 'package:online_barber_app/views/user/claim_buisness.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:online_barber_app/views/user/shop/products.dart';
import 'package:online_barber_app/views/user/shop/recent_orders.dart';
import '../auth/login_screen.dart';
import 'Drawer Pages/faqs.dart';


class AppDrawer extends StatefulWidget {
  final double screenWidth;

  const AppDrawer({super.key, required this.screenWidth});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
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
        DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection(
            'users').doc(_currentUser!.uid).get();
        if (snapshot.exists) {
          setState(() {
            _firstName = snapshot['firstName'];
          });
        }
      } catch (e) {
        log('Error fetching first name: $e');
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      log('Error signing out: $e');
    }
  }

  Future<void> _reauthenticate() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User canceled the sign-in
      return;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser
        .authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(
        credential);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        log('No user is currently signed in.');
        return;
      }

      // Re-authenticate the user before deletion
      await _reauthenticate();

      // Get user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(
          'users').doc(user.uid).get();
      if (userDoc.exists) {
        // Copy user data to the deleted_users collection
        final Map<String, dynamic>? userData = userDoc.data() as Map<
            String,
            dynamic>?;
        if (userData != null) {
          userData['deleted_at'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance.collection('deleted_users').doc(
              user.uid).set(userData);

          // Delete user data from Firestore
          await FirebaseFirestore.instance.collection('users')
              .doc(user.uid)
              .delete();
        } else {
          log('Failed to cast user data.');
        }
      } else {
        log('User data does not exist.');
      }

      // Delete the user from FirebaseAuth
      await user.delete();

      // Sign out the user
      await _signOut(context);

      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        log(
            'The user must reauthenticate before this operation can be executed.');
        await _reauthenticate();
        await _deleteAccount(context); // Retry account deletion
      } else {
        log('Error deleting account: $e');
      }
    } finally {
      Navigator.of(context).pop(); // Close the dialog
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
                    backgroundImage: _currentUser?.photoURL != null &&
                        _currentUser!.photoURL!.isNotEmpty
                        ? NetworkImage(_currentUser!.photoURL!)
                        : null,
                    child: _currentUser?.photoURL == null ||
                        _currentUser!.photoURL!.isEmpty
                        ? const Icon(
                        Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hello 👋, ${_firstName ?? 'User'}',
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
              title: Text(AppLocalizations
                  .of(context)
                  ?.profile ?? 'Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(AppLocalizations
                  .of(context)
                  ?.my_appointments ?? 'My Appointments'),
              onTap: () {
                Navigator.pop(context);
                final userId = LocalStorage.getUserID();
                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentsShow(uid: userId),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User ID not found.')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(AppLocalizations
                  .of(context)
                  ?.notifications ?? 'Notifications'),
              onTap: () {
                Navigator.pop(context);
                final userId = LocalStorage.getUserID();
                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(uid: userId),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User ID not found.')),
                  );
                }
              },
            ),
            ExpansionTile(
              leading: const Icon(Icons.shopping_cart),
              title: Text(AppLocalizations
                  .of(context)
                  ?.shop ?? 'Shop'),
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.card_travel),
                  title: Text(AppLocalizations
                      .of(context)
                      ?.products ?? 'Products'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProductDisplayPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(AppLocalizations
                      .of(context)
                      ?.recent_orders ?? 'Recent Orders'),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RecentOrdersPage(userId: LocalStorage.getUserID()
                                .toString()),
                      ),
                    );
                  },
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.contact_mail),
              title: Text(AppLocalizations
                  .of(context)
                  ?.contact_admin ?? 'Contact Admin'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_rounded),
              title: Text(AppLocalizations
                  .of(context)
                  ?.find_your_shop ?? 'Find Your Shop'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClaimBusiness(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign),
              title: Text(AppLocalizations
                  .of(context)
                  ?.announcements ?? 'Announcements'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserAnnouncementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_answer),
              title: Text(AppLocalizations
                  .of(context)
                  ?.faqs ?? 'FAQs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FAQ(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: Text(AppLocalizations
                  .of(context)
                  ?.privacy_policy ?? 'Privacy Policy'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicy(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                  Icons.do_disturb_alt_sharp, color: Colors.red),
              title: Text(AppLocalizations
                  .of(context)
                  ?.delete_account ?? 'Delete Account'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(AppLocalizations
                          .of(context)
                          ?.confirm_delete_account ?? 'Confirm Delete Account'),
                      content: Text(AppLocalizations
                          .of(context)
                          ?.are_you_sure_delete_account ??
                          'Are you sure you want to delete your account? This action cannot be undone.'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: Text(AppLocalizations
                              .of(context)
                              ?.cancel ?? 'Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context)
                                .pop(); // Close the dialog before deletion
                            await _deleteAccount(
                                context); // Proceed with account deletion
                          },
                          child: Text(AppLocalizations
                              .of(context)
                              ?.delete ?? 'Delete'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(AppLocalizations
                  .of(context)
                  ?.sign_out ?? 'Sign Out'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(AppLocalizations
                          .of(context)
                          ?.confirm_sign_out ?? 'Confirm Sign Out'),
                      content: Text(AppLocalizations
                          .of(context)
                          ?.are_you_sure_sign_out ??
                          'Are you sure you want to sign out?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: Text(AppLocalizations
                              .of(context)
                              ?.cancel ?? 'Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context)
                                .pop(); // Close the dialog before sign-out
                            await _signOut(context); // Proceed with sign-out
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                            ); // Navigate to login screen
                          },
                          child: Text(AppLocalizations
                              .of(context)
                              ?.sign_out ?? 'Sign Out'),
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
