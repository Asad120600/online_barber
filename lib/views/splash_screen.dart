import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/admin/admin_panel.dart';
import 'package:online_barber_app/views/auth/login_screen.dart';
import 'package:online_barber_app/views/barber/barber_panel.dart';
import 'package:online_barber_app/views/user/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // ✅ Wait for 4 seconds, then check login status
    Timer(const Duration(seconds: 4), () {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String? userType = LocalStorage.getUserType(); // 1 = admin, 2 = barber, 3 = user

      switch (userType) {
        case '1':
          Get.offAll(() => const AdminPanel());
          break;
        case '2':
          Get.offAll(() => BarberPanel(barberId: user.uid));
          break;
        case '3':
          Get.offAll(() => const HomeScreen());
          break;
        default:
          Get.offAll(() => const LoginScreen());
      }
    } else {
      Get.offAll(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/img/background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: const Stack(
        children: <Widget>[
          Positioned(
            bottom: 16.0,
            left: 6,
            right: 0,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Welcome to 👋',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontFamily: 'Acumin Pro',
                      fontWeight: FontWeight.normal,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Online Barber ',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 30,
                      fontFamily: 'Acumin Pro',
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 20.0),
                  Text(
                    'The Best Barber And Salon App in this century for your Good Looks And Beauty',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Acumin Pro',
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
