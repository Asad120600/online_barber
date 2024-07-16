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
          default: // Regular user
            await _firestore.collection('users').doc(user.uid).set(userData);
            break;
        }
      }
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password, String userType) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc;

        switch (userType) {
          case '1': // Admin
          // Check if trying to login as admin
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
          // Check if trying to login as barber
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
          // Check if trying to login as regular user
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
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Check if the user already exists in Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        DocumentSnapshot barberDoc = await _firestore.collection('barbers').doc(user.uid).get();

        if (barberDoc.exists) {
          print("Barber logged in");
          // Navigate to barber dashboard or perform barber-specific actions
        } else if (userDoc.exists) {
          print(" user logged in");
          // Navigate to user home screen or perform user-specific actions
        } else {
          // New user, handle accordingly
          print("New user logged in");
        }
      }
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print(e.toString());
    }
  }
}
