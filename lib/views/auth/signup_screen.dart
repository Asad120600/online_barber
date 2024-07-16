import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  bool isBarberSelected = false; // Add this line
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
  final TextEditingController barberFirstNameController = TextEditingController(); // Add this line
  final TextEditingController barberLastNameController = TextEditingController(); // Add this line
  final TextEditingController barberEmailController = TextEditingController(); // Add this line
  final TextEditingController barberPasswordController = TextEditingController(); // Add this line
  final TextEditingController barberConfirmPasswordController = TextEditingController(); // Add this line
  final TextEditingController barberPhoneNumberController = TextEditingController(); // Add this line

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
    String firstName = isUserSelected
        ? userFirstNameController.text.trim()
        : isAdminSelected
        ? adminFirstNameController.text.trim()
        : barberFirstNameController.text.trim();
    String lastName = isUserSelected
        ? userLastNameController.text.trim()
        : isAdminSelected
        ? adminLastNameController.text.trim()
        : barberLastNameController.text.trim();
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
    String confirmPassword = isUserSelected
        ? userConfirmPasswordController.text.trim()
        : isAdminSelected
        ? adminConfirmPasswordController.text.trim()
        : barberConfirmPasswordController.text.trim();
    String phoneNumber = isUserSelected
        ? userPhoneNumberController.text.trim()
        : isAdminSelected
        ? adminPhoneNumberController.text.trim()
        : barberPhoneNumberController.text.trim();
    String userType = isUserSelected ? '3' : isAdminSelected ? '1' : '2'; // Barber user type

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match. Please try again.'),
        ),
      );
      return;
    }

    User? user = await _authController.signUpWithEmail(
      email,
      password,
      firstName,
      lastName,
      phoneNumber,
      userType,
      context,
    );

    if (user != null) {
      _showLoadingDialog(context);
      // Navigate to login screen after successful signup
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      });
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
                        isBarberSelected = false;
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
                        isBarberSelected = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAdminSelected ? Colors.orange : Colors.grey,
                    ),
                    child: const Text("Admin"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isUserSelected = false;
                        isAdminSelected = false;
                        isBarberSelected = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBarberSelected ? Colors.orange : Colors.grey,
                    ),
                    child: const Text("Barber"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: isBarberSelected ? barberFirstNameController : (isUserSelected ? userFirstNameController : adminFirstNameController),
                decoration: InputDecoration(
                  labelText: isBarberSelected ? 'First Name' : (isUserSelected ? 'First Name' : 'Admin First Name'),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: isBarberSelected ? barberLastNameController : (isUserSelected ? userLastNameController : adminLastNameController),
                decoration: InputDecoration(
                  labelText: isBarberSelected ? 'Last Name' : (isUserSelected ? 'Last Name' : 'Admin Last Name'),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: isBarberSelected ? barberEmailController : (isUserSelected ? userEmailController : adminEmailController),
                decoration: InputDecoration(
                  labelText: isBarberSelected ? 'Email' : (isUserSelected ? 'Email' : 'Admin Email'),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: isBarberSelected ? barberPhoneNumberController : (isUserSelected ? userPhoneNumberController : adminPhoneNumberController),
                decoration: InputDecoration(
                  labelText: isBarberSelected ? 'Phone Number' : (isUserSelected ? 'Phone Number' : 'Admin Phone Number'),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: isBarberSelected ? barberPasswordController : (isUserSelected ? userPasswordController : adminPasswordController),
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: isBarberSelected ? 'Password' : (isUserSelected ? 'Password' : 'Admin Password'),
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
                controller: isBarberSelected ? barberConfirmPasswordController : (isUserSelected ? userConfirmPasswordController : adminConfirmPasswordController),
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
                child: Text('Sign Up'),

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
