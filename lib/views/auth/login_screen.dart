// old login
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:online_barber_app/controllers/auth_controller.dart';
import 'package:online_barber_app/controllers/language_change_controller.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/admin/admin_panel.dart';
import 'package:online_barber_app/views/auth/signup_screen.dart';
import 'package:online_barber_app/views/barber/barber_panel.dart';
import 'package:online_barber_app/views/user/home_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

enum Language { english, urdu, arabic, spanish, french }

class _LoginScreenState extends State<LoginScreen> {
  bool isUserSelected = true;
  bool isAdminSelected = false;
  bool isBarberSelected = false;
  bool isPasswordVisible = false;

  final TextEditingController userEmailController = TextEditingController();
  final TextEditingController userPasswordController = TextEditingController();
  final TextEditingController adminEmailController = TextEditingController();
  final TextEditingController adminPasswordController = TextEditingController();
  final TextEditingController barberEmailController = TextEditingController();
  final TextEditingController barberPasswordController =
      TextEditingController();

  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _showLoadingDialog() async {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent dialog from being dismissed by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LoadingDots(),
              const SizedBox(width: 20.0),
              Text(AppLocalizations.of(context)!.logging_in),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    _showLoadingDialog(); // Show the loading dialog

    String email = isUserSelected
        ? userEmailController.text.trim()
        : isAdminSelected
            ? adminEmailController.text.trim()
            : barberEmailController.text.trim();
    String password = isUserSelected
        ? userPasswordController.text.trim()
        : isAdminSelected
            ? adminPasswordController.text.trim()
            : barberPasswordController.text.trim();
    String userType = isUserSelected
        ? '3'
        : isAdminSelected
            ? '1'
            : '2';

    if (email.isNotEmpty && password.isNotEmpty) {
      try {
        User? user =
            await _authController.signInWithEmail(email, password, userType);

        if (user != null) {
          LocalStorage.setUserID(userID: user.uid);

          if (isBarberSelected) {
            LocalStorage.setBarberId(user.uid); // Save barber ID here
          }

          LocalStorage.setUserType(userType); // Save user type here

          Navigator.of(context).pop(); // Dismiss the loading dialog

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
            default: // Regular user
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
              break;
          }
        } else {
          Navigator.of(context).pop(); // Dismiss the loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.failed_to_sign_in),
            ),
          );
        }
      } catch (e) {
        Navigator.of(context).pop(); // Dismiss the loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.error_during_login(e.toString())),
          ),
        );
      }
    } else {
      Navigator.of(context).pop(); // Dismiss the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.please_enter_email_and_password),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    _showLoadingDialog(); // Show the loading dialog

    try {
      // Call the signInWithGoogle method from the AuthController
      User? user = await _authController.signInWithGoogle(isBarberSelected
          ? '2'
          : isAdminSelected
              ? '1'
              : '3');

      if (user != null) {
        // Save the user data in LocalStorage
        LocalStorage.setUserID(userID: user.uid);
        String userType = isAdminSelected
            ? '1' // Admin
            : isBarberSelected
                ? '2' // Barber
                : '3'; // Regular User

        if (isBarberSelected) {
          LocalStorage.setBarberId(user.uid);
        }

        LocalStorage.setUserType(userType); // Save user type here

        Navigator.of(context).pop(); // Dismiss the loading dialog

        // Navigate to the appropriate screen based on the user type
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
          default: // Regular user
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
            break;
        }
      } else {
        // If the user is null, show a failure message and dismiss the loading dialog
        Navigator.of(context).pop(); // Dismiss the loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.failed_to_sign_in_google),
          ),
        );
      }
    } catch (e) {
      // Log the error and show the error message
      debugPrint('Error during Google sign-in: $e');

      Navigator.of(context).pop(); // Dismiss the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!
              .error_during_google_sign_in(e.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        actions: [
          Consumer<LanguageChangeController>(
            builder: (context, provider, child) {
              return PopupMenuButton(
                icon: const Icon(Icons.language),
                onSelected: (Language item) {
                  if (Language.english.name == item.name) {
                    provider.changeLanguage(const Locale("en"));
                  } else if (Language.urdu.name == item.name) {
                    provider.changeLanguage(const Locale("ur"));
                  } else if (Language.arabic.name == item.name) {
                    provider.changeLanguage(const Locale("ar"));
                  } else if (Language.spanish.name == item.name) {
                    provider.changeLanguage(const Locale("es"));
                  } else if (Language.french.name == item.name) {
                    provider.changeLanguage(const Locale("fr"));
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<Language>>[
                  PopupMenuItem(
                      value: Language.english,
                      child: Text(AppLocalizations.of(context)!.english)),
                  PopupMenuItem(
                      value: Language.urdu,
                      child: Text(AppLocalizations.of(context)!.urdu)),
                  PopupMenuItem(
                      value: Language.arabic,
                      child: Text(AppLocalizations.of(context)!.arabic)),
                  PopupMenuItem(
                      value: Language.spanish,
                      child: Text(AppLocalizations.of(context)!.spanish)),
                  PopupMenuItem(
                      value: Language.french,
                      child: Text(AppLocalizations.of(context)!.french)),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.1),
              Container(
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/img/login.png',
                  width: screenWidth * 0.55,
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
              Row(
                children: [
                  _buildRoleSelectionButton(
                      AppLocalizations.of(context)!.user, isUserSelected, () {
                    setState(() {
                      isUserSelected = true;
                      isAdminSelected = false;
                      isBarberSelected = false;
                    });
                  }),
                  const SizedBox(width: 10.0),
                  _buildRoleSelectionButton(
                      AppLocalizations.of(context)!.admin, isAdminSelected, () {
                    setState(() {
                      isUserSelected = false;
                      isAdminSelected = true;
                      isBarberSelected = false;
                    });
                  }),
                  const SizedBox(width: 10.0),
                  _buildRoleSelectionButton(
                      AppLocalizations.of(context)!.barber, isBarberSelected,
                      () {
                    setState(() {
                      isUserSelected = false;
                      isAdminSelected = false;
                      isBarberSelected = true;
                    });
                  }),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),
              _buildLoginForm(),
              SizedBox(height: screenHeight * 0.03),
              Button(
                onPressed: _handleLogin,
                child: Text(AppLocalizations.of(context)!.login),
              ),
              SizedBox(height: screenHeight * 0.02),
              if (!isAdminSelected) // Only show the Sign Up text if Admin is not selected
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignUpScreen()),
                    );
                  },
                  child: Text(
                    AppLocalizations.of(context)!.dont_have_account,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              SizedBox(height: screenHeight * 0.02),
              if (!isAdminSelected &&
                  !isBarberSelected) // Only show Google sign-in button if Admin or Barber is not selected
                TextButton(
                  onPressed: _handleGoogleSignIn,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/img/google_logo.png',
                        height: 25.0,
                      ),
                      const SizedBox(width: 10.0),
                      Text(
                        AppLocalizations.of(context)!.sign_in_with_google,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectionButton(
      String role, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          height: 40.0,
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Text(
            role,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 150),
          child: Text(
            isUserSelected
                ? AppLocalizations.of(context)!.login_user
                : isAdminSelected
                    ? AppLocalizations.of(context)!.login_admin
                    : AppLocalizations.of(context)!.login_barber,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10.0),
        TextField(
          controller: isUserSelected
              ? userEmailController
              : isAdminSelected
                  ? adminEmailController
                  : barberEmailController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.email,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
        const SizedBox(height: 10.0),
        TextField(
          controller: isUserSelected
              ? userPasswordController
              : isAdminSelected
                  ? adminPasswordController
                  : barberPasswordController,
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.password,
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  isPasswordVisible = !isPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
      ],
    );
  }
}
