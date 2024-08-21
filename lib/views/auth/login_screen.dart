import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:online_barber_app/controllers/auth_controller.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/admin/admin_panel.dart';
import 'package:online_barber_app/views/auth/signup_screen.dart';
import 'package:online_barber_app/views/barber/barber_panel.dart';
import 'package:online_barber_app/views/user/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

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
  final TextEditingController barberPasswordController = TextEditingController();

  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _showLoadingDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog from being dismissed by tapping outside
      builder: (BuildContext context) {
        return const AlertDialog(
          content:  Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingDots(),
              SizedBox(width: 20.0),
              Text('Logging in...'),
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
        User? user = await _authController.signInWithEmail(email, password, userType);

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
            const SnackBar(
              content: Text('Failed to sign in. Please try again.'),
            ),
          );
        }
      } catch (e) {
        Navigator.of(context).pop(); // Dismiss the loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during login: $e'),
          ),
        );
      }
    } else {
      Navigator.of(context).pop(); // Dismiss the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password.'),
        ),
      );
    }
  }



  Future<void> _handleGoogleSignIn() async {
    _showLoadingDialog(); // Show the loading dialog

    try {
      User? user = await _authController.signInWithGoogle(context);

      if (user != null) {
        LocalStorage.setUserID(userID: user.uid);
        String userType = isAdminSelected ? '1' : isBarberSelected ? '2' : '3';

        if (isBarberSelected) {
          LocalStorage.setBarberId(user.uid);
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
          const SnackBar(
            content: Text('Failed to sign in with Google. Please try again.'),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during Google sign-in: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.2),
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
                  _buildRoleSelectionButton('User', isUserSelected, () {
                    setState(() {
                      isUserSelected = true;
                      isAdminSelected = false;
                      isBarberSelected = false;
                    });
                  }),
                  const SizedBox(width: 10.0),
                  _buildRoleSelectionButton('Admin', isAdminSelected, () {
                    setState(() {
                      isUserSelected = false;
                      isAdminSelected = true;
                      isBarberSelected = false;
                    });
                  }),
                  const SizedBox(width: 10.0),
                  _buildRoleSelectionButton('Barber', isBarberSelected, () {
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
                child: const Text('LOGIN'),
              ),
              SizedBox(height: screenHeight * 0.02),
              if (!isAdminSelected) // Only show the Sign Up text if Admin is not selected
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    );
                  },
                  child: const Text(
                    'Don\'t have an account? Sign Up',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              SizedBox(height: screenHeight * 0.02),
              if (!isAdminSelected && !isBarberSelected) // Only show Google sign-in button if Admin or Barber is not selected
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
                      const Text(
                        'Sign in with Google',
                        style: TextStyle(
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

  Widget _buildRoleSelectionButton(String role, bool isSelected, VoidCallback onTap) {
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
            isUserSelected ? 'Login as User' : isAdminSelected ? 'Login as Admin' : 'Login as Barber',
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
            hintText: 'Email',
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
            hintText: 'Password',
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

