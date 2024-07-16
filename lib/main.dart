import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/admin/active_users.dart';
import 'package:online_barber_app/views/admin/deleted_users.dart';
import 'package:online_barber_app/views/splash_screen.dart';
import 'package:online_barber_app/views/auth/login_screen.dart';
import 'package:online_barber_app/views/user/profile.dart';
import 'package:online_barber_app/views/user/faqs.dart';
import 'package:online_barber_app/views/user/help.dart';
import 'package:online_barber_app/views/user/privacy_policy.dart';
import 'package:online_barber_app/views/user/show_appointments.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  LocalStorage.initStorage();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

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
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/profile': (context) =>  const ProfileScreen(),
        '/faqs': (context) => const FAQ(),
        '/help': (context) => const Help(),
        '/privacy_policy': (context) => const PrivacyPolicy(),
        '/active_users': (context) => ActiveUsers(),
        '/deleted_users': (context) => DeletedUsers(),
        '/AppointmentsShow':(context)=>AppointmentsShow(uid:LocalStorage.getUserID().toString()),
      },
    );
  }


}
