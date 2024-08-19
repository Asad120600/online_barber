import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions( apiKey: 'AIzaSyDcWHUoPk0MSdZzCN0uMflEy8ihLF4GbZM',
      appId: '1:868392948570:android:5b546940fa69da46b15963',
      messagingSenderId: '868392948570',
      projectId: 'online-barber-def19',
      )
  );
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
  requestPermission();
  requestLocationPermission();
  getToken();
  }

  void requestPermission() async {
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
      log("Permission granted");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      log("Permission Not Granted");
    } else {
      log("User Premission Declined");
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {

      if (message.notification != null) {
        log(
            'Message also contained a notification: ${message.notification?.title}');
      }
    });
  }
  Future<void> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      if (await Permission.location.request().isGranted) {
        // The user granted permission
        log("Location permission granted.");
      } else {
        // The user denied the permission
        log("Location permission denied.");
      }
    } else if (status.isPermanentlyDenied) {
      // Handle the case where the user has permanently denied the permission.
      openAppSettings();
    } else if (status.isGranted) {
      // Permission already granted
      log("Location permission already granted.");
    }
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
