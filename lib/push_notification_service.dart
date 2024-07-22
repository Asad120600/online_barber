import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;

class PushNotificationService{
  static Future<String>getAccessToken() async
  {
    final serviceAccountJson = {
      "type": "service_account",
    "project_id": "online-barber-641ba",
    "private_key_id": "63c0a2d65ba16feabdf07d3b0def23828516efc6",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDfJbVpt7GHQ3ay\nhSIZA9zleO3NfMTHzGdsxvNVekfAdJwdDDPRik49DdB4zh4D40PxGKXuEQTKqhcR\ntKPz1ulc+0G4JbArlp1y21MGqb4WMUoq7bKCBOhkdAfIs3/+k1f3lo7XNI79A45V\nUcnhFoM89IR8GzoE8KJR+3CTQH4KLOieiVHdOUWUlUvbKVuLJ7ddN/JhH+kbn/dO\nROp79mJboy8oRmaoy8dkNCPCkjV3/yZk7ASJeQSaZfEM4NbBqVR0H3Ce/H6wS2OZ\nGOXEFt4Uqu5fx6uNIuquZ0wwmOHfItwIXlm+bm6vgEqMQd9hyTBESbFiXOcEz9+C\n54VhsjeDAgMBAAECggEAWd/KqrsY7eU+m9UiMBgNsoCbqp0bdms9pqKUo/M9jeaJ\nb+uXvUfqjg2PzvAZR7CTjznBrto851FNPEzYkd+XmuL5i6zmQRAG9xkd3fukuzR7\n7kFRGavXW4oeDng5T3PRxL7nZgbdpkr12yg3WohiMD09VOz0V8QBZGqUY0Jg4UCH\ng/7rFSZcJTcfs1qFCPulGNRb9AjksYoS0ITiLOvNn3gxka5Z2i3CFqNHzwvHhz+3\npbofT1C1ONIZNwmEEZfHhV7bSp5VwYzZVZ69qTV+uLiUOTTNxxlQw48lhrkG2CfH\nAji4sXSCanVgHKu2E+CZx1e9oFd7aqXZdZwBa9/ADQKBgQD3nsOFwQHON5cZOEUO\nV5unpsKnog0UCLTHpk0UT5yDhUBnnD/whAlQgx+YR2yzQOsluqOftbmaCVJ2lgfR\nVxMvYvSJQWiavP5OOBdt9Yr8I4wMWoBxWKjUu4jxJ2JtlPkOw0TqkOQcyEyrvxXC\npPjwAPH9YtCVEuteCUWrhsCZjQKBgQDmsu0ent9J0piJo1S5Z22bX4ZlyYP/nNrS\nNr6VcRIjlp1FgROGdNXR+rmE2U9Bco10YUYXDzC+i/swFY3Df6TIpIAktaZQbjwn\n2ugwzvx3AfMeTzDwqUlE4G/tH21I5rFqhL/KbjavY3Kn5Lola/vB7el+POuCc4gR\nMJFoHGhpTwKBgQC0tqxxMBO2QUHHyRY0ymEx8HU9S/oJdfUhg8/bE+Lg5V3Ef/b1\n/BakKJ3lT7MX+zfh2B1UEJb8wPLq0sGv2MGKosheZ1sFGwrpYOxQdpPRQcwSs/Xr\nQs4sOxVNEfY2jTNav83K9qVUECZMbW9fF3EKD1aMGxKoyR73CQNMlFJ5fQKBgEW8\nwscl2XO0cJ3yvLLLHCwCpVrxnrBPVyqCl/wO0R/m8KXJDgDwIo62DwyksDuliDMt\nEIX59o8zO3xel5sIY+SvLXlrW9omaJLXrqbKezDyau63m6C0W8yxV8RDYsLN0cXU\nWTG1PVypYEh2cPrM+K6334RkoACwMeqYVuw04i8rAoGAaZZhL7y6f8o9DeCEWRUf\n7k0jLlpeHcTzQB2eEJdSUjUnU2AyTVp4+Tleo3LN2BA7/U5NoWz33Osd9ofyewpB\nXLyzDK0/Q/2FVTX5JnarA0f9CRuYjfkApcg+7WLnVIVDGTti9U10zsx6P08VkQzI\n0tFzAxYFyltMP6tUtptIN/Q=\n-----END PRIVATE KEY-----\n",
    "client_email": "online-barber@online-barber-641ba.iam.gserviceaccount.com",
    "client_id": "115820899205624106961",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/online-barber%40online-barber-641ba.iam.gserviceaccount.com",
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
    String endpointFirebaseCloudMessaging = 'https://fcm.googleapis.com/v1/projects/online-barber-641ba/messages:send';

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


  }

