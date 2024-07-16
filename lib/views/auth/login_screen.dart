import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:online_barber_app/controllers/auth_controller.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:online_barber_app/utils/shared_pref.dart';
import 'package:online_barber_app/views/admin/admin_panel.dart';
import 'package:online_barber_app/views/auth/signup_screen.dart';
import 'package:online_barber_app/views/barber/barber_panel.dart';
import 'package:online_barber_app/views/user/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

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

  Future<void> _handleLogin() async {
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
          print("========");
          print(user.uid);
          LocalStorage.setUserID(userID: user.uid);
          switch (userType) {
            case '1': // Admin
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminPanel(),
                ),
              );
              break;
            case '2':
              Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const BarberPanel(),
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
        String userType = '3';
        if (isAdminSelected) {
          userType = '1'; // Admin
        } else if (isBarberSelected) {
          print("========");
          print(user.uid);
          LocalStorage.setUserID(userID: user.uid);
          userType = '2'; // Barber
        }

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
                builder: (context) => const BarberPanel(),
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
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          isUserSelected = true;
                          isAdminSelected = false;
                          isBarberSelected = false;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: isUserSelected ? Colors.orange : Colors.transparent,
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: Text(
                          'User',
                          style: TextStyle(
                            color: isUserSelected ? Colors.white : Colors.black,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.0),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          isUserSelected = false;
                          isAdminSelected = true;
                          isBarberSelected = false;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: isAdminSelected ? Colors.orange : Colors.transparent,
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            color: isAdminSelected ? Colors.white : Colors.black,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.0),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          isUserSelected = false;
                          isAdminSelected = false;
                          isBarberSelected = true;
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: isBarberSelected ? Colors.orange : Colors.transparent,
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Text(
                          'Barber',
                          style: TextStyle(
                            color: isBarberSelected ? Colors.white : Colors.black,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),
              isUserSelected
                  ? Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 150),
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
                  TextFormField(
                    controller: userEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TextFormField(
                    controller: userPasswordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
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
              )
                  : isAdminSelected
                  ? Column(

                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 150),
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
                  TextFormField(
                    controller: adminEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Admin Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TextFormField(
                    controller: adminPasswordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Admin Password',
                      prefixIcon: Icon(Icons.lock),
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
              )
                  : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 150),
                    child: Text(
                      'Login as Barber',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro',
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: barberEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Barber Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TextFormField(
                    controller: barberPasswordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Barber Password',
                      prefixIcon: Icon(Icons.lock),
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
              ),
              SizedBox(height: screenHeight * 0.03),
              Button(
                child: Text('LOGIN'),
                onPressed: _handleLogin,
              ),
              SizedBox(height: screenHeight * 0.02),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  );
                },
                child: Text(
                  'Don\'t have an account? Sign Up',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14.0,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              if (!isAdminSelected && !isBarberSelected ) // Only show Google sign-in button if Admin is not selected
                TextButton(
                  onPressed: _handleGoogleSignIn,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/img/google_logo.png',
                        height: 25.0,
                      ),
                      SizedBox(width: 10.0),
                      Text(
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
}
