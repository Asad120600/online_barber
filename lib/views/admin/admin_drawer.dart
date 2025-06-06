import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:online_barber_app/views/admin/admin_shop/add_products.dart';
import 'package:online_barber_app/views/admin/admin_shop/all_products.dart';
import 'package:online_barber_app/views/admin/admin_shop/orders.dart';
import 'package:online_barber_app/views/admin/announcement_screen_send.dart';
import 'package:online_barber_app/views/admin/app_settings/faqs_settings.dart';
import 'package:online_barber_app/views/admin/barber admin/barber_stats.dart';
import 'package:online_barber_app/views/admin/chat/admin_contact_reply.dart';
import 'package:online_barber_app/views/admin/claim_request.dart';
import 'package:online_barber_app/views/admin/services/manage_services.dart';
import 'package:online_barber_app/views/admin/services/service_list.dart';
import 'package:online_barber_app/views/auth/login_screen.dart';
import 'package:online_barber_app/views/admin/users/active_users.dart';
import 'package:online_barber_app/views/admin/users/deleted_users.dart';
import 'package:online_barber_app/views/admin/app_settings/privacy_settings.dart';
import 'package:online_barber_app/views/admin/admin_profile.dart';
import 'barber admin/barber_screen.dart';

class AdminDrawer extends StatefulWidget {
  const AdminDrawer({super.key, required this.screenWidth});

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
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('admins')
            .doc(_currentUser!.uid)
            .get();
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

  /// ✅ Safe navigation helper using GetX and post-frame callback
  void navigateSafe(Widget page) {
    Get.back(); // Close drawer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.to(() => page);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return SizedBox(
      width: widget.screenWidth * 0.75,
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.orange),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.orange,
                    radius: 30,
                    child: Icon(Icons.supervisor_account,
                        size: 50, color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      localization.hello_admin(_firstName ?? ''),
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(localization.profile),
              onTap: () => navigateSafe(const AdminProfile()),
            ),
            ExpansionTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: Text(localization.shop),
              children: [
                ListTile(
                  leading: const Icon(Icons.production_quantity_limits_sharp),
                  title: Text(localization.all_products),
                  onTap: () => navigateSafe(const AllProductsPage()),
                ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(localization.add_products),
                  onTap: () => navigateSafe(const AddProducts()),
                ),
                ListTile(
                  leading: const Icon(Icons.history_toggle_off),
                  title: Text(localization.orders),
                  onTap: () => navigateSafe(const AdminOrdersPage()),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.supervised_user_circle_sharp),
              title: Text(localization.users),
              children: [
                ListTile(
                  leading: const Icon(Icons.group),
                  title: Text(localization.active_users),
                  onTap: () => navigateSafe(const ActiveUsers()),
                ),
                ListTile(
                  leading: const Icon(Icons.group_off),
                  title: Text(localization.deleted_users),
                  onTap: () => navigateSafe(const DeletedUsers()),
                ),
                ListTile(
                  leading: const Icon(Icons.content_cut),
                  title: Text(localization.barbers),
                  onTap: () => navigateSafe(BarberListScreen()),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.settings),
              title: Text(localization.app_settings),
              children: [
                ListTile(
                  title: Text(localization.privacy_policy),
                  onTap: () => navigateSafe(const PrivacySettings()),
                ),
                // ListTile(
                //   title: Text(localization.slide_show_settings),
                //   onTap: () => navigateSafe(const AdminSlideshowScreen()),
                // ),
                ListTile(
                  title: Text(localization.faqs_settings),
                  onTap: () => navigateSafe(const FAQsSettings()),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.miscellaneous_services_outlined),
              title: Text(localization.services),
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(localization.add_services),
                  onTap: () => navigateSafe(const ManageService()),
                ),
                ListTile(
                  leading: const Icon(Icons.manage_history),
                  title: Text(localization.manage_services),
                  onTap: () => navigateSafe(const ServiceList()),
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.query_stats_rounded),
              title: Text(localization.barberStats),
              onTap: () => navigateSafe(BarberStatsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: Text(localization.chat),
              onTap: () => navigateSafe(const AdminScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.campaign),
              title: Text(localization.announcement),
              onTap: () => navigateSafe(const AnnouncementScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.request_page_outlined),
              title: Text(localization.claim_requests),
              onTap: () => navigateSafe(const ClaimRequestsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(localization.signOut),
              onTap: () {
                Get.defaultDialog(
                  title: localization.confirmSignOut,
                  middleText: localization.signOutConfirmation,
                  textCancel: localization.cancel,
                  textConfirm: localization.signOut,
                  confirmTextColor: Colors.white,
                  onConfirm: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                      Get.back(); // close dialog
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Get.offAll(() => const LoginScreen());
                      });
                    } catch (e) {
                      log('Sign-out error: $e');
                      Get.snackbar('Error', 'Failed to sign out. Try again.');
                    }
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
