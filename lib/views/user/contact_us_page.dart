import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  void _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    try {
      final bool canLaunchEmail = await canLaunch(emailUri.toString());
      if (canLaunchEmail) {
        await launch(emailUri.toString());
      } else {
        throw 'Could not launch email';
      }
    } catch (e) {
      print(e); // You can also show a snackbar or dialog to inform the user.
    }
  }

  void _launchPhone(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    try {
      final bool canLaunchPhone = await canLaunch(phoneUri.toString());
      if (canLaunchPhone) {
        await launch(phoneUri.toString());
      } else {
        throw 'Could not launch phone';
      }
    } catch (e) {
      print(e); // You can also show a snackbar or dialog to inform the user.
    }
  }

  void _launchMap(String address) async {
    final Uri mapUri = Uri(
      scheme: 'geo',
      queryParameters: {'q': address},
    );
    try {
      final bool canLaunchMap = await canLaunch(mapUri.toString());
      if (canLaunchMap) {
        await launch(mapUri.toString());
      } else {
        throw 'Could not launch map';
      }
    } catch (e) {
      print(e); // You can also show a snackbar or dialog to inform the user.
    }
  }

  void _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      final bool canLaunchUrl = await canLaunch(uri.toString());
      if (canLaunchUrl) {
        await launch(uri.toString());
      } else {
        print('Could not launch URL: $url');
        // Optionally show a Snackbar or Dialog to inform the user
      }
    } catch (e) {
      print('Error launching URL: $e');
      // Optionally show a Snackbar or Dialog to inform the user
    }
  }

  final double iconSize = 35.0;
  final double paddingSize = 8.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Online Barber',
              style: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24.0),
            GestureDetector(
              onTap: () => _launchEmail('waseemafzal31@gmail.com'),
              child: const Row(
                children: [
                  Icon(Icons.email, color: Colors.orange),
                  SizedBox(width: 8.0),
                  Text(
                    'waseemafzal31@gmail.com',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black87,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            GestureDetector(
              onTap: () => _launchPhone('+92 341 7090031'),
              child: const Row(
                children: [
                  Icon(Icons.phone, color: Colors.orange),
                  SizedBox(width: 8.0),
                  Text(
                    '+92 341 7090031',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black87,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            GestureDetector(
              onTap: () => _launchMap('Multan, Pakistan'),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.orange),
                  SizedBox(width: 8.0),
                  Flexible(
                    child: Text(
                      'Multan, Pakistan',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.black87,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            const Divider(color: Colors.grey),
            // const Padding(
            //   padding: EdgeInsets.symmetric(vertical: 16.0),
            //   child: Center(
            //     child: Text(
            //       'Follow Us',
            //       style: TextStyle(
            //         fontSize: 20.0,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ),
            // ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     _socialMediaIcon(
            //       'assets/img/facebook.png',
            //       'https://www.facebook.com/',
            //     ),
            //     _socialMediaIcon(
            //       'assets/img/instagram.png',
            //       'https://www.instagram.com/',
            //     ),
            //     _socialMediaIcon(
            //       'assets/img/whatsapp.png',
            //       'https://www.whatsapp.com/',
            //     ),
            //     _socialMediaIcon(
            //       'assets/img/linkedin.png',
            //       'https://www.linkedin.com/',
            //     ),
            //     _socialMediaIcon(
            //       'assets/img/twitter.png',
            //       'https://www.twitter.com/',
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  // Widget _socialMediaIcon(String assetPath, String url) {
  //   return Flexible(
  //     child: Container(
  //       decoration: BoxDecoration(
  //         border: Border.all(color: Colors.blue),
  //         shape: BoxShape.circle,
  //       ),
  //       margin: const EdgeInsets.symmetric(horizontal: 7.0),
  //       child: GestureDetector(
  //         onTap: () => _launchUrl(url),
  //         child: Padding(
  //           padding: EdgeInsets.all(paddingSize),
  //           child: ClipOval(
  //             child: Image.asset(
  //               assetPath,
  //               width: iconSize,
  //               height: iconSize,
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
