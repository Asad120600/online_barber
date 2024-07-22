import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/admin/admin_panel.dart';
import 'package:online_barber_app/views/barber/barber_panel.dart';
import 'package:online_barber_app/views/user/home_screen.dart';
import 'auth/login_screen.dart';
import '../utils/button.dart';

class SlideshowScreen extends StatefulWidget {
  const SlideshowScreen({super.key});

  @override
  _SlideshowScreenState createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> {
  final List<String> images = [
    'assets/img/one.jpg',
    'assets/img/two.jpg',
    'assets/img/three.jpg',
  ];

  final List<String> texts = [
    'Find Barbers and Salons Easily in Your Hands',
    'Book Your Favorite Barber And Salon Quickly',
    'Come be Handsome with us Right Now',
  ];

  int currentIndex = 0;
  bool isCarouselCompleted = false;
  final CarouselController _carouselController = CarouselController();
  Timer? _slideshowTimer;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _startSlideshow();
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? userType = await LocalStorage.getUserType();
      switch (userType) {
        case '1': // Admin
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminPanel(),
            ),
          );
          break;
        case '2': // Barber
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BarberPanel(barberId: user.uid),
            ),
          );
          break;
        case '3': // Regular user
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
          break;
        default:
          break;
      }
    }
  }

  void _startSlideshow() {
    _slideshowTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          currentIndex = (currentIndex + 1) % images.length;
          if (currentIndex == 0) {
            isCarouselCompleted = true;
          }
        });
        _carouselController.nextPage();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: CarouselSlider(
              carouselController: _carouselController,
              options: CarouselOptions(
                height: MediaQuery.of(context).size.height * 0.6,
                autoPlay: false, // Disable autoPlay
                enlargeCenterPage: true,
                aspectRatio: 2.0,
                onPageChanged: (index, reason) {
                  setState(() {
                    currentIndex = index;
                  });
                },
              ),
              items: images.map((imagePath) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange, width: 2),
                        image: DecorationImage(
                          image: AssetImage(imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      texts[currentIndex],
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                        fontFamily: 'Acumin Pro',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Button(
                      onPressed: () {
                        // Navigate to the app's main screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Enter App',
                        style: TextStyle(
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    ),
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
