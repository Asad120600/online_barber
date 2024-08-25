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
      "project_id": "online-barber-def19",
      "private_key_id": "4ada7a91b241fc08ba63457daa3915f51a36f0a4",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQCw3G+oHwo6elLc\nw7QDAOPmbVZl7y7OwKbwBa7of+WM8euFkmnYsbypNwAkBjNlcr0MD+PyEgri8OBJ\nzSj9sjN7hf2Fxo++7rPDgyMKw+zrqmbYIo1PEXrZbrooWBCRdFca5AB3pJS3yDHB\nxoOgKRYSTUfQNKd1OaSjoBX5u/xp7yvl/BKThHsdfW97cO42FsGeNBCqkBziQiu6\nMTIyWDkRlpugxZWb8FsayBAeUkGsDa3L3gYAeEPyk51XxIIqAgH0GkSFPiocaT0S\niGTyKHMmd1HTG3NGgannrwA36wykVeo9cwr4ZDfst4gBNiJJe2uqWZ/phHapvglR\nozsMEuoFAgMBAAECggEARkJb7Qrfsllz35WzRlotLxYSc44wJxxrdQCc+moMlBBr\nAvYmLFp3WzWpTaZU9qE9LrSFVl4KixsrzsW82gPX5eNV0rYN1sjXCv1mh1lMHlbk\nYkpfnqCQEB6nv200r8Pq8pjPAriUB+p0sckd8xs/VGf09mZke/I5UHNBJ6OhY6dh\nAOcBQRDE4Ea1tkmv8bqY888OaP4pSEoryqS/DWj0eT0OVOI/TkePhLe2hkoKS7yd\nPCpO3qORQMxP43eJL8PtkQ8UFSRUwTNpN5U2hY6PJcICN+Z0t42p4FQwNeQu9THf\npBlnhE2e/niCwOSOx932Wn7TRrxqVRnFQLLoGWAtJQKBgQDq/l51qZ3Ys+lXTubo\nGwtXLWViJ30AB/ByO1cA2rN1jfZwNJQ5vOWCxZfT3d4zblJc9WSOlvauqY7gth4Z\nd8LwVbgl3NSjzQoS+PVk5IDvgjs6RC+SpUhp5rXz220/9syA+7G7CHMGKoGC5edQ\ndWhFfibkRjI4yIiYTHnwJlwQzwKBgQDAq8C3BPX781T3m31n616JXHaEgVutSz7u\n3tN9W+5Bj3gYSdIxrEvGFwhDHXjbsTrjaM/8ZyHUzWI4sg6XliSL0oLVHYSnmVzh\nDRyXWEkP561bjcYui7SZiFeMEghd0V6cLoqJbudHpVOndr26c46ykocP8yDUpIxp\nAHCfXn/E6wKBgQCr4Ay6xqqa20wp/Z3J2i37P0rN9c/pe+UTx+8kwtFLg9/hxbM8\nX7sGYPthjP9+Yox/TUSVPjmDGqVUGh/9xKiiHDAqEVC91bQumETz3GWpyHkFbuXU\nvmsuef5PNAi+JgcBuBYQlGd89Q3w7bK4GIeBfHl5sRX+jj3KFvWA/q2L5QKBgQCB\nshwkFz7Ov1ou44hjb9lPdeKCB+ICoWhXu79532xezYj2MJtBvM21JsP1Cd3VZVRS\nyLdZHMN1UFwR9ipEeFlZlfdkJl6pw172T7EzX8au4jGcM694naqQv2rPa0Qeg1XA\npMO1B+bAH9ZUIGZPIIKqSmCIqA0tlya9eAJYBXDUyQKBgQCB6HWWxgfW97mVOpeW\nxcYIJydd5ZorAyDXcQjQB4A+cr8+cMZIyMSAPGDB0+e27lFk2oH2afaMq3/52GCx\nu3nYhW0SEzObdZgnm2fnqVClqkw7ZYYYF0Y8YLl0rebyk34iI61r9T/MKJCI+QKz\nEP4Zo7/KV0gtx3m+9C2Cn8QSYw==\n-----END PRIVATE KEY-----\n",
      "client_email": "online-barber@online-barber-def19.iam.gserviceaccount.com",
      "client_id": "102350083882465130174",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/online-barber%40online-barber-def19.iam.gserviceaccount.com",
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
    String endpointFirebaseCloudMessaging = 'https://fcm.googleapis.com/v1/projects/online-barber-def19/messages:send';

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
    String endpointFirebaseCloudMessaging = 'https://fcm.googleapis.com/v1/projects/online-barber-def19/messages:send';

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



