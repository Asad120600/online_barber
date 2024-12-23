import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageChangeController with ChangeNotifier {
  Locale? _appLocale;

  Locale? get appLocale => _appLocale;

  // Initialize the app locale based on saved preference
  Future<void> initializeLocale() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? languageCode = sp.getString('language_code');
    _appLocale = languageCode != null ? Locale(languageCode) : const Locale("en");
    notifyListeners();
  }

  // Change the language dynamically and save the preference
  void changeLanguage(Locale locale) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    _appLocale = locale;

    // Save the selected language code to preferences
    await sp.setString('language_code', locale.languageCode);

    notifyListeners();
  }
}
