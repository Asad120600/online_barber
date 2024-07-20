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
      home:  const SplashScreen(),
    );
  }


}
