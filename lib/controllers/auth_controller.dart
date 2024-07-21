import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import '../models/admin_model.dart';
import '../models/barber_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<bool> signUpWithEmail(
      String email,
      String password,
      String firstName,
      String lastName,
      String phone,
      String userType,
      BuildContext context
      ) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        var userData = BaseUserModel(
          uid: user.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          userType: userType,
          phone: phone,
        ).toMap();

        // Set user data based on user type
        switch (userType) {
          case '1': // Admin
            userData = AdminModel(
              uid: user.uid,
              email: email,
              firstName: firstName,
              lastName: lastName,
              userType: userType,
              phone: phone,
            ).toMap();
            await _firestore.collection('admins').doc(user.uid).set(userData);
            break;
          case '2': // Barber
            userData = Barber(
              id: user.uid,
              email: email,
              name: firstName,
              userType: userType,
              phoneNumber: phone,
              address: '',
              imageUrl: '',
            ).toMap();
            await _firestore.collection('barbers').doc(user.uid).set(userData);
            break;

          case '3': // User
            userData = BaseUserModel(
              uid: user.uid,
              email: email,
              firstName: firstName,
              lastName: lastName,
              userType: userType,
              phone: phone,

            ).toMap();
            await _firestore.collection('users').doc(user.uid).set(userData);
            break;
            default: // Regular user
            break;
        }
        return true; // Return true on successful signup
      }
      return false; // Return false if user is null
    } catch (e) {
      print("Sign Up Error: ${e.toString()}");
      return false; // Return false on error
    }
  }

  Future<User?> signInWithEmail(String email, String password, String userType) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc;

        switch (userType) {
          case '1': // Admin
            userDoc = await _firestore.collection('admins').doc(user.uid).get();
            if (userDoc.exists) {
              print("Admin logged in");
              // Navigate to admin panel or perform admin-specific actions
            } else {
              print("Admin document does not exist for uid: ${user.uid}");
              await _auth.signOut(); // Sign out user if trying to login as admin with user credentials
              return null;
            }
            break;
          case '2': // Barber
            userDoc = await _firestore.collection('barbers').doc(user.uid).get();
            if (userDoc.exists) {
              print("Barber logged in");
              // Navigate to barber dashboard or perform barber-specific actions
            } else {
              print("Barber document does not exist for uid: ${user.uid}");
              await _auth.signOut(); // Sign out user if trying to login as barber with user credentials
              return null;
            }
            break;
          default: // Regular user
            userDoc = await _firestore.collection('users').doc(user.uid).get();
            if (userDoc.exists) {
              print("Regular user logged in");
              // Navigate to user home screen or perform user-specific actions
            } else {
              print("User document does not exist for uid: ${user.uid}");
              await _auth.signOut(); // Sign out user if trying to login as regular user with admin/barber credentials
              return null;
            }
            break;
        }
        return user;
      }
      return null; // Return null if user is null
    } catch (e) {
      print("Sign In Error: ${e.toString()}");
      return null; // Return null on error
    }
  }

  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Google sign-in aborted by user.");
        return null; // User aborted Google sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          var userData = {
            'uid': user.uid,
            'email': user.email,
            'firstName': user.displayName?.split(" ")[0] ?? '',
            'lastName': user.displayName?.split(" ")[1] ?? '',
            'userType': '3', // Default userType for Google sign-in
            'phone': user.phoneNumber ?? '',
          };

          await _firestore.collection('users').doc(user.uid).set(userData);
        }
        return user;
      }
      return null; // Return null if user is null
    } catch (e) {
      print("Google Sign-In Error: ${e.toString()}");
      return null; // Return null on error
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print("Sign Out Error: ${e.toString()}");
    }
  }
}
