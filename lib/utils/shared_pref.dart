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



  static void logout() {
    prefs.clear();
  }


}
