import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/splash_screen.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  LocalStorage.initStorage();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
  requestPremission();
  getToken();
  }

  void requestPremission() async {
    FirebaseMessaging message = FirebaseMessaging.instance;

    NotificationSettings settings = await message.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log("Premission granted");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      log("Premission Not Granted");
    } else {
      log("User Premission Declined");
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {

      if (message.notification != null) {
        print(
            'Message also contained a notification: ${message.notification?.title}');
      }
    });
  }
  String myToken="";
  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((value) {
      setState(() {
        myToken = value.toString();
        log("My Token: $myToken");
        LocalStorage.setFirebaseToken(myToken);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Online Barber App',
      theme: ThemeData(
        fontFamily: 'Acumin Pro',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home:  const SplashScreen(),
    );
  }
}
