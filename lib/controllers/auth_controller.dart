import 'dart:developer'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/user_model.dart';
import '../utils/shared_pref.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Sign up with email and password
Future<bool> signUpWithEmail(
  String email,
  String password,
  String firstName,
  String lastName,
  String phone,
  String userType,
  BuildContext context,
) async {
  try {
    // Create user with email and password.
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;

    if (user != null) {
      String? token;
      if (!kIsWeb) {
        token = await _firebaseMessaging.getToken();
        if (token != null) {
          LocalStorage.setFirebaseToken(token);
        }
      }

      // Create user data model.
      var userData = BaseUserModel(
        uid: user.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        userType: userType,
        phone: phone,
        token: token ?? '',
      ).toMap();

      // Store user data in Firestore based on user type.
      switch (userType) {
        case '1': // Admin
          await _firestore.collection('admins').doc(user.uid).set(userData);
          break;
        case '2': // Barber
          await _firestore.collection('barbers').doc(user.uid).set(userData);
          break;
        default: // Regular User
          await _firestore.collection('users').doc(user.uid).set(userData);
          break;
      }

      // Send email verification only for non-admin users.
      if (userType != '1') {
        await sendEmailVerification(user);
      }

      return true;
    }
    return false;
  } catch (e) {
    log("Sign-Up Error: ${e.toString()}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Sign-Up Error: ${e.toString()}")),
    );
    return false;
  }
}

  // Send email verification
  Future<void> sendEmailVerification(User user) async {
    try {
      await user.sendEmailVerification();
      log("Verification email sent.");
    } catch (e) {
      log("Error sending verification email: $e");
    }
  }

  // Check if the user's email is verified
  Future<bool> checkEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // Reload user data to get the latest info
      return user.emailVerified;
    }
    return false;
  }

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password, String userType) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        String? token;
        if (!kIsWeb) {
          token = await _firebaseMessaging.getToken();
          if (token != null) {
            await updateTokenInFirestore(user.uid, token);
            LocalStorage.setFirebaseToken(token);
          }
        }

        // Retrieve user document based on type.
        DocumentSnapshot userDoc;
        switch (userType) {
          case '1':
            userDoc = await _firestore.collection('admins').doc(user.uid).get();
            break;
          case '2':
            userDoc = await _firestore.collection('barbers').doc(user.uid).get();
            break;
          default:
            userDoc = await _firestore.collection('users').doc(user.uid).get();
            break;
        }

        if (!userDoc.exists) {
          log("User document not found for type: $userType");
          await _auth.signOut();
          return null;
        }

        // Skip email verification for admin users.
        if (userType != '1') {
          bool isVerified = await checkEmailVerification(); // This is the correct method to call
          if (!isVerified) {
            log("Email is not verified.");
            await _auth.signOut();
            return null;
          }
        }

        return user;
      }
      return null;
    } catch (e) {
      log("Sign-In Error: ${e.toString()}");
      return null;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle(String userType) async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        log("Google Sign-In failed.");
        return null; // The user canceled the sign-in
      }

      // Obtain the Google authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase using the Google credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        String? token;
        if (!kIsWeb) {
          token = await _firebaseMessaging.getToken();
          if (token != null) {
            await updateTokenInFirestore(user.uid, token);
            LocalStorage.setFirebaseToken(token);
          }
        }

        // Store user data in Firestore based on user type
        DocumentSnapshot userDoc;
        switch (userType) {
          case '1':
            userDoc = await _firestore.collection('admins').doc(user.uid).get();
            break;
          case '2':
            userDoc = await _firestore.collection('barbers').doc(user.uid).get();
            break;
          default:
            userDoc = await _firestore.collection('users').doc(user.uid).get();
            break;
        }

        if (!userDoc.exists) {
          log("User document not found for type: $userType");
          await _auth.signOut();
          return null;
        }

        return user;
      }

      return null;
    } catch (e) {
      log("Google Sign-In Error: ${e.toString()}");
      return null;
    }
  }

  // Update Firebase token in Firestore
  Future<void> updateTokenInFirestore(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({'token': token});
    } catch (e) {
      log("Failed to update token: $e");
    }
  }

  // Sign out the user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      log("Sign-Out Error: ${e.toString()}");
    }
  }
}
