import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static late SharedPreferences prefs;

  static Future initStorage() async {
    prefs = await SharedPreferences.getInstance();
  }

  static void setUserID({required String userID}) {
    prefs.setString('userID', userID);
  }

  static String? getUserID() {
    String? userID = prefs.getString('userID');
    return userID;
  }

  static void setBarberId(String barberId) {
    prefs.setString('barberID', barberId);
  }

  Future<void> saveBarberId(String barberId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('barberId', barberId);
  }

  static String? getBarberId() {
    return prefs.getString('barberID');
  }

  String getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? '';
  }

  static void logout() {
    prefs.clear();
  }
}
