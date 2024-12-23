import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class PushNotificationService{
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static Future<String>getAccessToken() async
  {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "online-barber-85e57",
      "private_key_id": "caed0b68b949d6ea0563e548d0fe86763f1fb487",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDRNQVxT5j8KR4U\nIxaiIRm7bkOnf2nIhVsRI1GJFjlsb5Z8edplFrWG9STFV45Smm2l2DO+yX9bVHzn\nf8VfnNyXp5G0MBXOn4wjeX5GqCliKuAm5Z8e9MwOpIkfupkqeIuWUcG/MXG8O/rY\nLfiaCvURcAK1bFWQSSEc5gB0+TlGIZz74tuUEL6rgrUPSWxIDv/K2uhMSh0wNx8S\nkWTEXOMYW+8YVEDgq48EH4gRr48lF9vh6MohNnuutNHsOMhPLo3N1cHlLsc2D7WV\nag3J8yLmNe8nOTNlczx6zY3tQFvZI0dWder1kHmEp13vQCCzJ7Cx1m9nAycr82nx\n41i0SOsFAgMBAAECggEAJdrMtdCb04DTJvykY0jPAam1hzDYYMa0kDjOT5pcYKEe\nXz6jRGhkB1wDP8wUfiDgV0J0NoD6UPnMMg1eFutoxO42wJ50y7L15hNdRIa4GkG8\n1nz1GmJcLAgcocefYF54j4YSozhcpp1JyeUjlygFaRbV/qLwJo/89GAv0/qmoOgv\nYgDMtfmlJKo7G9r8RsVw9moqo9ovB3qhsQxKQk3JdiShI2ibX6GhHGUxlYGHcvHk\nD2Ae+goW3mC8czvgmImfBVtCFtDgOgRfo9B4pYj2zKtVXPzu+5ctxyp5qZraREPs\nHxVGfFUChEiESXGsuTGbH8qd5iGVQ8z2QCxTzFM6/wKBgQDnko9s59Tr1FiOo7/S\nN+C0BvUrPltc6dElUgi3LEtn41VS9LZI4IFosQgU9t5f9H3Rs1n4lgFvdV6zdSYQ\nh0XaNEUC5A22ccyvdp22wdn9+sMwwrHS4afWg+dWV0jOG88For8Te8nWFpiiw1It\nozS6O4zhuFT/Fd7Ag6rwe1qBjwKBgQDnRoAt7L3NPhZvNmsgrgQY7ckyuARBUup0\n8INs9TVPuwqeg1JZ3/+mEgTlMUQehkmaamVGnIey7+np1aG9yL8JIa6Mo2UyKllJ\n1mPYOWcO+QYtcdTS/rDen12fmvba1pJ0LKQaF/YXgzD9Vt5exGJkf2yxxZ4phjxW\n2pyISbRYKwKBgAU6whJridtpiDZwbDyLFn/6SD8ZwWZvwVFecOPyFCHceGjPLe6n\nY0TB+rS+fnccRlsd+cIrYQzrUaAr3RgyddlfpM9T5xtfpoev3g/qgMnDh/Tp8Koa\nfnfRsr+4aOR+rEYsTrRZ70zuZbQHRSvSq7Yo8h2G1CSOkeE3F/0mS/zxAoGAX19x\naH7iXosmEUKtttJMGkOk3ueHybB5wzOT3xDXpUOKw4eAJFP9RuzTW/iPEM9r9uO9\nU/sk8qOBIM7aXjs0nH1pT9Hp32AbZhmlHvu9Bi2nYII6s7AYHBY4M6Nh/SjTSFlI\nawJKl7OgNjjmhsoRkUQC/ORzrsgOhfqs5n8OgfUCgYBbnJLWYXzSZDkdqdrkPDIw\nA86MZDXlK9gH/JCT+0SPNQNDboYFgyrUj+naT6zDJbTNhTqLyMTjapXSneoX7dJr\nRj7eALbY6VdYf73FOLjlmDlfMZwzq0C2h3w0ugpcUwrLn7YNLsbcQtLz9iV+98aQ\newciFQPOzsicnM2QRxRLfQ==\n-----END PRIVATE KEY-----\n",
      "client_email": "barber-80@online-barber-85e57.iam.gserviceaccount.com",
      "client_id": "103132873409992062945",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/barber-80%40online-barber-85e57.iam.gserviceaccount.com",
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

  static sendNotification(String token, BuildContext context, String message, String notificationBody) async {

    final String serverkey = await getAccessToken();
    String endpointFirebaseCloudMessaging = 'https://fcm.googleapis.com/v1/projects/online-barber-85e57/messages:send';

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
    String endpointFirebaseCloudMessaging = 'https://fcm.googleapis.com/v1/projects/online-barber-85e57/messages:send';

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



