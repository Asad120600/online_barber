import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:online_barber_app/views/auth/login_screen.dart';
import 'package:online_barber_app/controllers/auth_controller.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isUserSelected = true;
  bool isBarberSelected = false;
  bool isPasswordVisible = false;
  bool isLoading = false; // Add this line for loading state

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final AuthController _authController = AuthController();
  final TextEditingController phoneNumberController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void dispose() {
    phoneNumberController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    setState(() {
      isLoading = true; // Start loading
    });

    String firstName = firstNameController.text.trim();
    String lastName = lastNameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();
    String phoneNumber =
        phoneNumberController.text; // Get the phone number text
    String userType = isUserSelected ? '3' : '2'; // 3 for user, 2 for barber

    // Validation
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.required_fields_error),
        ),
      );
      setState(() {
        isLoading = false; // Stop loading
      });
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.password_mismatch),
        ),
      );
      setState(() {
        isLoading = false; // Stop loading
      });
      return;
    }

    // Sign up and send verification email
    bool signUpSuccess = await _authController.signUpWithEmail(
      email,
      password,
      firstName,
      lastName,
      phoneNumber,
      userType,
      context,
    );

    setState(() {
      isLoading = false; // Stop loading
    });

    if (signUpSuccess) {
      User? user = FirebaseAuth.instance.currentUser; // Get the current user
      if (user != null) {
        // Send email verification
        await _authController.sendEmailVerification(user); // Pass the user
        _showEmailVerificationDialog();

        // Check email verification automatically after sending email
        _checkEmailVerification(user);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User not found after sign up."),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.sign_up_failed),
        ),
      );
    }
  }

  void _checkEmailVerification(User user) async {
    // Start a loop or a delay to keep checking for email verification
    bool isVerified = false;
    while (!isVerified) {
      await Future.delayed(const Duration(seconds: 5)); // Check every 5 seconds
      isVerified =
          await _authController.checkEmailVerification(); // Check if verified
      if (isVerified) {
        // If verified, show the verified dialog and navigate to login
        _showEmailVerifiedDialog(context);
        break;
      }
    }
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text("Verify Email"),
          content: Text("Email is being verified"),
          actions: [
            // Removed the check verification button here
          ],
        );
      },
    );
  }

  void _showEmailVerifiedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Email Verified"),
          content: const Text("Your email has been verified successfully!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text("Go to Login"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.05),
              Container(
                margin: EdgeInsets.only(bottom: screenHeight * 0.000001),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/img/login.png',
                  width: screenWidth * 0.55,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isUserSelected = true;
                        isBarberSelected = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isUserSelected ? Colors.orange : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.user),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isUserSelected = false;
                        isBarberSelected = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isBarberSelected ? Colors.orange : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.barber),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.first_name,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.last_name,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.email,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              IntlPhoneField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                      borderSide: const BorderSide(),
                      borderRadius: BorderRadius.circular(20)),
                ),
                initialCountryCode: 'PK',
                onChanged: (phone) {
                  // Update the phoneNumberController with the complete phone number
                  phoneNumberController.text = phone.completeNumber;
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.password,
                  suffixIcon: IconButton(
                    icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.orange),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: confirmPasswordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.confirm_password,
                  suffixIcon: IconButton(
                    icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.orange),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Show loading indicator while the process is ongoing
              isLoading
                  ? const LoadingDots() // Loading indicator
                  : Button(
                      onPressed: _handleSignUp,
                      child: Text(AppLocalizations.of(context)!.sign_up),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
