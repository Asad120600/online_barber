  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:online_barber_app/controllers/auth_controller.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
  import 'package:online_barber_app/views/admin/admin_panel.dart';
  import 'package:online_barber_app/views/auth/signup_screen.dart';
  import 'package:online_barber_app/views/user/home_screen.dart';
  import 'package:sign_in_button/sign_in_button.dart';
  import '../../utils/button.dart';

  class LoginScreen extends StatefulWidget {

    const LoginScreen({Key? key}) : super(key: key);

    @override
    _LoginScreenState createState() => _LoginScreenState();
  }

  class _LoginScreenState extends State<LoginScreen> {
    bool isUserSelected = true;
    bool isAdminSelected = false;
    bool isPasswordVisible = false;

    final TextEditingController userEmailController = TextEditingController();
    final TextEditingController userPasswordController = TextEditingController();
    final TextEditingController adminEmailController = TextEditingController();
    final TextEditingController adminPasswordController = TextEditingController();

    final AuthController _authController = AuthController();

    Future<void> _handleLogin() async {
      String email = isUserSelected
          ? userEmailController.text.trim()
          : adminEmailController.text.trim();
      String password = isUserSelected
          ? userPasswordController.text.trim()
          : adminPasswordController.text.trim();

      if (email.isNotEmpty && password.isNotEmpty) {
        try {
          User? user = await _authController.signInWithEmail(email, password, isUserSelected ? '3' : '1');
          if (user != null) {
            print("========");
            print(user.uid);
            LocalStorage.setUserID(userID: user.uid);
            if (isUserSelected) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            } else if (isAdminSelected) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>  AdminPanel(),
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to sign in. Please try again.'),
              ),
            );
          }
        } catch (e) {
          print('Error during login: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error during login: $e'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter email and password.'),
          ),
        );
      }
    }

    Future<void> _handleGoogleSignIn() async {
      try {
        User? user = await _authController.signInWithGoogle(context);
        if (user != null) {
          print("========");
          print(user.uid);
          LocalStorage.setUserID(userID: user.uid);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to sign in with Google. Please try again.'),
            ),
          );
        }
      } catch (e) {
        print('Error during Google sign-in: $e');
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.05),
                Container(
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/img/login.png',
                    width: screenWidth * 0.6,
                    height: screenWidth * 0.8,
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
                      child: const Text(
                        "User",
                        style: TextStyle(color: Colors.white),
                      ),
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
                      child: const Text(
                        "Admin",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (isUserSelected) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: Text(
                        'Login as User',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro',
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: userEmailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: userPasswordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
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
                ],

                if (isAdminSelected) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: Text(
                        'Login as Admin',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro',
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: adminEmailController,
                    decoration: const InputDecoration(
                      labelText: "Admin Email",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: adminPasswordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Admin Password",
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
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
                ],
                const SizedBox(height: 20),

                Button(
                  onPressed: _handleLogin,
                  child: const Text(
                    "Login",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(fontSize: 15),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Signup",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (isUserSelected) ...[
                  Container(
                    width: 250,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _handleGoogleSignIn,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Image.asset(
                              'assets/img/google_logo.png',
                              height: 30.0,
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text(
                                'Sign up with Google',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
  }
