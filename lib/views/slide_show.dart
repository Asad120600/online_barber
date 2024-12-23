import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
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
  List<Map<String, dynamic>> _slides = [];
  int currentIndex = 0;
  Timer? _slideshowTimer;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchSlides();
    _startSlideshow();
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {  // Added mounted check here
      String? userType = LocalStorage.getUserType();
      switch (userType) {
        case '1': // Admin
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>  const AdminPanel(),
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

  Future<void> _fetchSlides() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('slideshow_images').get();
      final slides = snapshot.docs.map((doc) {
        return {
          'imageUrl': doc['imageUrl'],
          'text': doc['text'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _slides = slides;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load slides')),
        );
      }
    }
  }

  void _startSlideshow() {
    if (_slides.isNotEmpty) {
      _slideshowTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted) {
          setState(() {
            currentIndex = (currentIndex + 1) % _slides.length;
          });
        } else {
          timer.cancel();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _slides.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            flex: 6,
            child: Swiper(
              itemCount: _slides.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  margin: const EdgeInsets.only(left: 15, right: 15, top: 25),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange, width: 2),
                    image: DecorationImage(
                      image: NetworkImage(_slides[index]['imageUrl'] as String),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
              onIndexChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              autoplay: true,
              autoplayDelay: 2000,
              loop: true,
              pagination: const SwiperPagination(),
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
                  SizedBox(
                    height: 100, // Set a fixed height for the text container
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        _slides.isNotEmpty ? _slides[currentIndex]['text'] as String : '',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                          fontFamily: 'Acumin Pro',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Button(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Continue',
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
