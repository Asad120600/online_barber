import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/service.dart';

class Appointment {
  final DateTime date;
  final TimeOfDay time;
  final List<Service> services;
  final String address;
  final String phoneNumber;

  Appointment({
    required this.date,
    required this.time,
    required this.services,
    required this.address,
    required this.phoneNumber, required String id, required String uid, required String userName,
  });
}

class GlobalState {
  static List<Appointment> appointments = [];
  static User? currentUser; // Optional: Store current authenticated user

  static void setUser(User? user) {
    currentUser = user;
  }

  static User? getUser() {
    return currentUser;
  }

  static String? getUserId() {
    return currentUser?.uid;
  }

  static void addAppointment(Appointment appointment) {
    appointments.add(appointment);
  }

  static List<Appointment> getAppointments() {
    return appointments;
  }

  static void clearAppointments() {
    appointments.clear();
  }
}
