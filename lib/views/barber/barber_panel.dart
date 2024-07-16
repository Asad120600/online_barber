import 'package:flutter/material.dart';

import 'barber_drawer.dart';

class BarberPanel extends StatefulWidget {
  const BarberPanel({super.key});

  @override
  State<BarberPanel> createState() => _BarberPanelState();
}

class _BarberPanelState extends State<BarberPanel> {

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Panel'),
      ),
      endDrawer: BarberDrawer(screenWidth:screenWidth ),
    );
  }
}
