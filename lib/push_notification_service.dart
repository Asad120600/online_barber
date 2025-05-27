import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class PushNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static Future<String> getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "online-barber-85e57",
      "private_key_id": "15fa5da91810f402d810e5404a2269bc047550a1",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDDXkBer7FL1vgi\nGQvsNEfOE/8fd2aGYADC7Db/lmhGvs30pX/A/ZjuRmGhATOFKGmLmpJKyzRa3NNy\nccSfEz+byg98VpD3L1aU9hu3Q9dne/8D2L4AfFVv5PRK2YJzRARa2NJh/Q6AdOYT\nyaK6tXFMAahZfWCNsp0WaYHWGCDn2rcy2e3clZGYPNHI47W3343hUjj4ahrN/EE+\nvRGJd4+lMWrMf29ekNpWgF6M9Iz9flxT8NhEWJUCgxowjQGEWrGT/8QzPBYc2UbU\n+Rv4aINc+i0DksTxK4bpm8Mvys9xXqnf4uuEbBCt3fuYKH9vemneus5xaC5t5wj8\nVLmAOwSpAgMBAAECggEAWvy4SeDVV5bEdUzo6pbmoilZ9hOrogVwFVfhvWMVKW2P\nidLSDtWMtdv9d/iRQAC0NxpD66V7up2BtJkbk2Jpi2qtj6DZXuWjEzkTa2SjG0T6\nXZZB1wQQ3k3pIDrwsDILPSwhvxUV/elzhd+wc/gwzc8v0o27vAJlepykpUsTeCbo\nyPT4rBOOmnGfJfNC9Vci3eH/Da2nlxj3LtnCLhgFoHl5LzqDYG4mjjfl7r5QMTGy\nLxzDDDBmuexnKIrApFn8ULaoO6MKnOEvLmzLkOMHB0MCJUvV2/U7RiwFDbs6YWEw\nCGQaLVUCgndDU2eMj2uEkbIe8B29gboo2GM/j7+KCQKBgQD7xvpZQ8H6RwwMpnT0\nzcr6gV+F5qigGNxZrpFmWEPc4q386PhdSlEem22H6v7uMGTO3cq+OVQzLKl92Roz\nMIpkX5nux0QHOod3SKLWnoYTNKe0rp4vPJwYAd2Vcaf3cQ9yXWsC+rUJVtNaWrvZ\nxampBH/5LkGeDejLuTgBP6gvbwKBgQDGpRPR++E03a1tSd3g/966FRvF6QD+qx9I\nEe6zVEa9cPH2D4N+FYLS/om4VP6jJmSXZvWwOD8eqphdT5CnuCe55kCvtaZhLovA\nFcovS4DpBHUU1opw5zYDZpDxjo958JyjLHrOPWWBKbOA2+e9pKXtabLih3f5pCbh\nOyj/0meBZwKBgQCaoHw2ADgMdj+/MSeZBR5ItNWujZc4I6yIY36mpUSgTpLeRVHr\nMW4aZwhgtgD01cHDjlEqfFjqyN4bDQ9bKs+Dj3chPz3XVqnFp1Vii576ApeQjsFV\nb1rKH7MvScsHW2dKLHdBMCmo36sTza+ashtdUwcpSLBB2ncDTvBHTAoFfwKBgCmn\nB6bqN+jL6seVy46YWG2Qa4huOSUtYJvOFs1HiKXEfxfnXN0dSZdQhDRArjwrmsAc\neLwAr0uQ3e4C9wQUG1BhtYKihkauaeNXLlQIcvlpU9uQuOq/sJW59f6QtAkPqOiW\nNRH10cjpo5gLhGZBlgFYPog9e6y+/OARdaFezxFVAoGBAPLi7TvEv1T5CWzeDWuN\nDzplrYwvUpjbB10cwhID+JaCb1HokfXp36dem2AKAG0OZgzCYd7mAxIiH1vi1k6m\nn0CQ/9ceEeY3jeYS6faRtfZ5iyAUz4Px1pMbWYjEYPArySi+0krfk58rVLBAbtbq\nmQKXsgEvsI2cD3gbSnFOU+Te\n-----END PRIVATE KEY-----\n",
      "client_email":
          "getonlinebarber@online-barber-85e57.iam.gserviceaccount.com",
      "client_id": "110233518098990916594",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/getonlinebarber%40online-barber-85e57.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };
    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
            scopes,
            client);

    client.close();

    return credentials.accessToken.data;
  }

  static sendNotification(String token, BuildContext context, String message,
      String notificationBody) async {
    final String serverkey = await getAccessToken();
    String endpointFirebaseCloudMessaging =
        'https://fcm.googleapis.com/v1/projects/online-barber-85e57/messages:send';

    final Map<String, dynamic> notificationMessage = {
      'message': {
        'token': token,
        'notification': {
          'title': message,
          'body': notificationBody,
        },
        'data': {'name': 'name'}
      }
    };
    final http.Response response = await http.post(
      Uri.parse(endpointFirebaseCloudMessaging),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverkey'
      },
      body: jsonEncode(notificationMessage),
    );

    if (response.statusCode == 200) {
      log("Notification sent successfully");
    } else {
      log("Notification not sent: ${response.body}");
    }
  }

  static Future<void> sendNotificationToUser(String token, BuildContext context,
      String message, String notificationBody) async {
    final String serverkey = await getAccessToken();
    String endpointFirebaseCloudMessaging =
        'https://fcm.googleapis.com/v1/projects/online-barber-85e57/messages:send';

    final Map<String, dynamic> notificationMessage = {
      'message': {
        'token': token,
        'notification': {
          'title': message,
          'body': notificationBody,
        },
        'data': {'name': 'name'}
      }
    };
    final http.Response response = await http.post(
      Uri.parse(endpointFirebaseCloudMessaging),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverkey'
      },
      body: jsonEncode(notificationMessage),
    );

    if (response.statusCode == 200) {
      log("Notification sent successfully");
    } else {
      log("Notification not sent: ${response.body}");
    }
  }

  static void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
