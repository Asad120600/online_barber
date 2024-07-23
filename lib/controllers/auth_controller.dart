import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:online_barber_app/utils/shared_pref.dart';

import '../models/user_model.dart';
import '../models/admin_model.dart';
import '../models/barber_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

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
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          LocalStorage.setFirebaseToken(token);
        }

        var userData = BaseUserModel(
          uid: user.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          userType: userType,
          phone: phone,
          token: token ?? '',
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
              token: token ?? '',
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
              token: token ?? '',
              shopName: '',
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
              token: token ?? '',
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
      log("Sign Up Error: ${e.toString()}");
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
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await updateTokenInFirestore(user.uid, token);
          LocalStorage.setFirebaseToken(token);
        }

        DocumentSnapshot userDoc;

        switch (userType) {
          case '1': // Admin
            userDoc = await _firestore.collection('admins').doc(user.uid).get();
            if (userDoc.exists) {
              log("Admin logged in");
              // Navigate to admin panel or perform admin-specific actions
            } else {
              log("Admin document does not exist for uid: ${user.uid}");
              await _auth.signOut(); // Sign out user if trying to login as admin with user credentials
              return null;
            }
            break;
          case '2': // Barber
            userDoc = await _firestore.collection('barbers').doc(user.uid).get();
            if (userDoc.exists) {
              log("Barber logged in");
              // Navigate to barber dashboard or perform barber-specific actions
            } else {
              log("Barber document does not exist for uid: ${user.uid}");
              await _auth.signOut(); // Sign out user if trying to login as barber with user credentials
              return null;
            }
            break;
          default: // Regular user
            userDoc = await _firestore.collection('users').doc(user.uid).get();
            if (userDoc.exists) {
              log("Regular user logged in");
              // Navigate to user home screen or perform user-specific actions
            } else {
              log("User document does not exist for uid: ${user.uid}");
              await _auth.signOut(); // Sign out user if trying to login as regular user with admin/barber credentials
              return null;
            }
            break;
        }
        return user;
      }
      return null; // Return null if user is null
    } catch (e) {
      log("Sign In Error: ${e.toString()}");
      return null; // Return null on error
    }
  }

  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        log("Google sign-in aborted by user.");
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
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await updateTokenInFirestore(user.uid, token);
          LocalStorage.setFirebaseToken(token);
        }

        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          var userData = {
            'uid': user.uid,
            'email': user.email,
            'firstName': user.displayName?.split(" ")[0] ?? '',
            'lastName': user.displayName?.split(" ")[1] ?? '',
            'userType': '3', // Default userType for Google sign-in
            'phone': user.phoneNumber ?? '',
            'token': token ?? '',
          };

          await _firestore.collection('users').doc(user.uid).set(userData);
        }
        return user;
      }
      return null; // Return null if user is null
    } catch (e) {
      log("Google Sign-In Error: ${e.toString()}");
      return null; // Return null on error
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      log("Sign Out Error: ${e.toString()}");
    }
  }

  Future<void> updateTokenInFirestore(String userId, String token) async {
    try {
      // Check user type and update the corresponding collection
      var userDoc = await _firestore.collection('admins').doc(userId).get();
      if (userDoc.exists) {
        await _firestore.collection('admins').doc(userId).update({'token': token});
        return;
      }

      userDoc = await _firestore.collection('barbers').doc(userId).get();
      if (userDoc.exists) {
        await _firestore.collection('barbers').doc(userId).update({'token': token});
        return;
      }

      userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        await _firestore.collection('users').doc(userId).update({'token': token});
        return;
      }
    } catch (e) {
      log("Failed to update token in Firestore: $e");
    }
  }
}
