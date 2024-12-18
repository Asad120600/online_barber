import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;

class PushNotificationService{
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static Future<String>getAccessToken() async
  {
    final serviceAccountJson = {
  "type": "service_account",
  "project_id": "get-barber-online",
  "private_key_id": "947a99bb5d1e61d735395f702433fd6374cc8816",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCzHxTeJGTUUgDL\nWe6jrTob6ZcMumDXIDhV2FWtZOa1O+AvLI/aWo5dpbWYcT0VoZXy88Ci97h3cfqD\neeZON1PypZxxaYYy9wlzpQgbhlYoFuWq40GJ0OWexeu/uJd2EI7wdc2u7g7oxZmn\n/9HrQJk8IGRQI2VwO3YQ/Nb48CJDZPwy1l9DbV2PFNnFhQ6H9BNeti3hkVgcGTUH\n76jz5zdLtBEWAhTa0xo+16v4lBofE8QYXARFjE8W4Z/yD8/fT/YVDqKPbzRHAdBn\nytptU0TTD+vxALCOXKeyG91br1/YWDG8INq82Guj6jrJyNO4Yay5VnvpNKyZ5pon\ndZCo8CM1AgMBAAECggEAAUZc6ai639/7wswWnoB/IEUQrQsui+7BqarASHffKAuB\nRhSuAInZWRqdfkK1ZiVY8BbYCiY6iv1QdneJo9408THWx24V84royvqVfqH9d+Fa\nunG/oI3su5DIKsOaPM/FW8hTv/5QbUux2kZAEHRazYNq1unXzW1bW8QJzzUZ4jeR\nLbBmkT/bO1WVeS21NMNPmhyn+xJwmkheMOzIZznMNf+JuhvGyHVDAjjuK9c4F3G2\nYyUfb9aCWlryncv1q8RSMOfj5+t5KkNJmmgYofohc+gJot0zg76X7qYu5MDQPrx2\nSXteZ872gztBjwDu+pQcuD1vjlD3qDna0w3ckKRmSQKBgQDaTFSFcQ+jspZbBZDx\nFzNOm4OHBLdJLz0Uyzd/4aaJzDlcv+r5z4FdrkB1mHx8gPKk5s6JNfem6BjucJJ5\nIegSLERbtob+K4Pq7GwdxAjhayNjWjHVNziSQt+WFxT3eQcRbBGXxvPp6LBN+CHQ\nOnUlIVGTe7LxyfTWJCYs0d30DwKBgQDSDp68viGzO0yoKiUODwVa+LhFr36kiwA1\n+AHzZyaFXLxZbI9cCyw4hKv5Vi6U9c5mzZFuF+ddbtUWkgEbX0FASytmyKkrw24d\nYwVBcEflZeLn1cTkVZ45V2Ot70SbmZfKe00olIwHijPCWvTV5tKxWxMLsGvKgBUr\nD37rrJYgewKBgH+gmNnbnDUsuFNHEdKiqdCPg3pw+2fCQofht/UATInL6M2dNxgO\nhafrtKwMFtwD19kpSB9Yeg4PLGRbVIeVl0TotJ6aPJplfp7e0uckMbz5EpuHpBLw\nUhbRGj96BzwYelVpRW/jVb+v10P+imZfhxXKQRNlAt3yIT8Bq4AQwx9pAoGBAM/w\nQRs+bEXs8dmWvs/H9tkzVddF/uwL3c2PEP9OoUdrodg0K0ZGmSPp0gQlWD+FhSkn\nXkvJxfMsAC0zo3zhMsrenrxE75KvB5Z3q4A4EjP4REKTzzDpwJOq+rX4IcaWqTh8\nDsmZI3VjThGb0LreoLuJGLV9k3cGi+3wjQfn9UV5AoGBAJrQe36uzteYu+ow64ao\nZsFEJ4zsNMHj5MHTU2nifu8Rzo+cflxRiKkpsCw6JVkJ6ouVxxlhZMjXeqyz+vCl\nvUCllIag5TGqxlzeZ5j3Nl46x0Cws9dhmsTNT1hRbyD7yGOh79Vo8gb7jNZveDXq\nTT7aOyMhvxSB/IMaxISCsOqb\n-----END PRIVATE KEY-----\n",
  "client_email": "getonlinebarber@get-barber-online.iam.gserviceaccount.com",
  "client_id": "108047588287389014774",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/getonlinebarber%40get-barber-online.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
;
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

  static sendNotification(String token, BuildContext context, String message, String notificationBody) async {

    final String serverkey = await getAccessToken();
    String endpointFirebaseCloudMessaging = 'https://fcm.googleapis.com/v1/projects/get-barber-online/messages:send';

    final Map<String, dynamic> notificationMessage = {
      'message': {
        'token': token,
        'notification': {
          'title': message,
          'body': notificationBody,
        },
        'data': {
          'name': 'name'
        }
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

  static Future<void> sendNotificationToUser(String token, BuildContext context, String message, String notificationBody) async {
    final String serverkey = await getAccessToken();
    String endpointFirebaseCloudMessaging = 'https://fcm.googleapis.com/v1/projects/get-barber-online/messages:send';

    final Map<String, dynamic> notificationMessage = {
      'message': {
        'token': token,
        'notification': {
          'title': message,
          'body': notificationBody,
        },
        'data': {
          'name': 'name'
        }
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



