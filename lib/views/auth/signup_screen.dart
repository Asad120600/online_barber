import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/views/auth/login_screen.dart';
import 'package:online_barber_app/controllers/auth_controller.dart';
import 'package:online_barber_app/utils/button.dart'; // Adjust this import as per your project structure

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool isUserSelected = true;
  bool isAdminSelected = false;
  bool isPasswordVisible = false;

  final TextEditingController userFirstNameController = TextEditingController();
  final TextEditingController userLastNameController = TextEditingController();
  final TextEditingController userEmailController = TextEditingController();
  final TextEditingController userPasswordController = TextEditingController();
  final TextEditingController userConfirmPasswordController = TextEditingController();
  final TextEditingController userPhoneNumberController = TextEditingController(); // Add this line
  final TextEditingController adminFirstNameController = TextEditingController();
  final TextEditingController adminLastNameController = TextEditingController();
  final TextEditingController adminEmailController = TextEditingController();
  final TextEditingController adminPasswordController = TextEditingController();
  final TextEditingController adminConfirmPasswordController = TextEditingController();
  final TextEditingController adminPhoneNumberController = TextEditingController(); // Add this line

  final AuthController _authController = AuthController(); // Initialize AuthController

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/img/done.png', // Replace with your image path
                  width: 100, // Adjust width as needed
                  height: 100, // Adjust height as needed
                ),
                const SizedBox(height: 20),
                const Text(
                  "Congratulations!",
                  style: TextStyle(
                    fontFamily: 'Acumin Pro',
                    fontSize: 20,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Your account is ready to use. You will be redirected shortly...",
                  style: TextStyle(
                    fontFamily: 'Acumin Pro',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      if (isUserSelected) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      } else if (isAdminSelected) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    });
  }

  Future<void> _handleSignUp() async {
    String firstName = isUserSelected ? userFirstNameController.text.trim() : adminFirstNameController.text.trim();
    String lastName = isUserSelected ? userLastNameController.text.trim() : adminLastNameController.text.trim();
    String email = isUserSelected ? userEmailController.text.trim() : adminEmailController.text.trim();
    String password = isUserSelected ? userPasswordController.text.trim() : adminPasswordController.text.trim();
    String confirmPassword = isUserSelected ? userConfirmPasswordController.text.trim() : adminConfirmPasswordController.text.trim();
    String phoneNumber = isUserSelected ? userPhoneNumberController.text.trim() : adminPhoneNumberController.text.trim(); // Add this line
    String userType = isUserSelected ? '3' : '1'; // Determine user type based on selection

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match. Please try again.'),
        ),
      );
      return;
    }

    User? user = await _authController.signUpWithEmail(email, password, firstName, lastName, phoneNumber, userType, context);

    if (user != null) {
      _showLoadingDialog(context);
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign up failed. Please try again.'),
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
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.05), // Adjust the height as needed
              Container(
                margin: EdgeInsets.only(bottom: screenHeight * 0.000001),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/img/login.png', // Replace with your image path
                  width: screenWidth * 0.6, // Adjust width as needed
                  height: screenWidth * 0.8, // Adjust height as needed
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isUserSelected = true;
                        isAdminSelected = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUserSelected ? Colors.orange : Colors.grey,
                    ),
                    child: const Text("User"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isUserSelected = false;
                        isAdminSelected = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAdminSelected ? Colors.orange : Colors.grey,
                    ),
                    child: const Text("Admin"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: isUserSelected ? userFirstNameController : adminFirstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: isUserSelected ? userLastNameController : adminLastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: isUserSelected ? userEmailController : adminEmailController,
                decoration: InputDecoration(
                  labelText: isUserSelected ? 'Email' : 'Admin Email',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: isUserSelected ? userPhoneNumberController : adminPhoneNumberController, // Add this TextField
                decoration: InputDecoration(
                  labelText: isUserSelected ? 'Phone Number' : 'Admin Phone Number',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: isUserSelected ? userPasswordController : adminPasswordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: isUserSelected ? 'Password' : 'Admin Password',
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
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: isUserSelected ? userConfirmPasswordController : adminConfirmPasswordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
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
                ),
              ),
              const SizedBox(height: 20),
              Button(
                onPressed: _handleSignUp,
                child: const Text("Sign Up"),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                      // Navigate to login screen
                    },
                    child: const Text("Login"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
