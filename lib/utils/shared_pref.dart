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
    return prefs.getString('userID');
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

  static void setUserType(String userType) {
    prefs.setString('userType', userType);
  }

  static String? getUserType() {
    return prefs.getString('userType');
  }


  static void setFirebaseToken(String token) {
    prefs.setString('token', token);
  }

  static String? getFirebaseToken() {
    return prefs.getString('token');
  }

  static void logout() {
    prefs.clear();
  }
}
