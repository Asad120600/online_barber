import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/admin_model.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signUpWithEmail(String email, String password, String firstName, String lastName, String phone, String userType, BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
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

        if (userType == '1') {
          userData = AdminModel(
            uid: user.uid,
            email: email,
            firstName: firstName,
            lastName: lastName,
            userType: userType,
            phone: phone,
            // Initialize additional admin-specific fields
          ).toMap();
        }

        // Create collections if they don't exist
        await _firestore.collection('users').doc(user.uid).set(userData);
        if (userType == '1') {
          await _firestore.collection('admins').doc(user.uid).set(userData);
        }
      }
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password, String s) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        DocumentSnapshot adminDoc = await _firestore.collection('admins').doc(user.uid).get();

        if (adminDoc.exists) {
          // User is an admin
          print("Admin logged in");
          // Redirect or perform admin-specific actions
        } else if (userDoc.exists) {
          // User is a regular user
          print("Regular user logged in");
          // Redirect or perform regular user actions
        } else {
          // Handle the case where neither document exists
          print("User document does not exist for uid: ${user.uid}");
          // You might want to handle this case differently based on your application's logic
        }
      }
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }


  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

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
            'email': user.email,
            'firstName': user.displayName?.split(" ")[0] ?? '',
            'lastName': user.displayName?.split(" ")[1] ?? '',
            'userType': '3', // Default userType for Google sign-in
          };

          await _firestore.collection('users').doc(user.uid).set(userData);
        }
      }
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
