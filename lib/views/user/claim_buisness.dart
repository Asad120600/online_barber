import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:online_barber_app/utils/claim_buisness_user_dialog.dart';

class ClaimBusiness extends StatefulWidget {
  const ClaimBusiness({super.key});

  @override
  State<ClaimBusiness> createState() => _ClaimBusinessState();
}

class _ClaimBusinessState extends State<ClaimBusiness> {
  final CollectionReference barbersRef = FirebaseFirestore.instance.collection('barbers');
  final CollectionReference claimsRef = FirebaseFirestore.instance.collection('claim_business');
  String? adminUid; // Store admin UID

  @override
  void initState() {
    super.initState();
    fetchAdminUid(); // Fetch admin UID on initialization
  }

  // Method to fetch admin UID
  Future<void> fetchAdminUid() async {
    try {
      var adminSnapshot = await FirebaseFirestore.instance.collection('admins').limit(1).get();
      if (adminSnapshot.docs.isNotEmpty) {
        setState(() {
          adminUid = adminSnapshot.docs.first.id; // Store admin UID
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin UID: $e');
    }
  }

  Future<bool> isBusinessClaimed(String barberName) async {
    final querySnapshot = await claimsRef.where('barberName', isEqualTo: barberName).get();
    return querySnapshot.docs.isNotEmpty;
  }

  void showClaimDialog(String barberName) {
    if (adminUid != null) {
      showDialog(
        context: context,
        builder: (context) {
          return ClaimBusinessDialog(
            barberName: barberName,
            onSubmit: (String barberName, String shopName, String address, String phoneNumber, String email, String nationalId) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Claim submitted for $barberName!')),
              );
            },
            adminUid: adminUid!, // Pass admin UID to dialog
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching admin UID.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Claim Business')),
      body: StreamBuilder<QuerySnapshot>(
        stream: barbersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No barbers available"));
          }

          final barbers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: barbers.length,
            itemBuilder: (context, index) {
              var barber = barbers[index];
              var name = barber['name'] ?? 'No Name';
              var shopName = barber['shopName'] ?? 'No Shop Name';
              var address = barber['address'] ?? 'No Address';

              return FutureBuilder<bool>(
                future: isBusinessClaimed(name),
                builder: (context, claimedSnapshot) {
                  bool isClaimed = claimedSnapshot.data ?? false;
                  return _buildBarberCard(name, shopName, address, isClaimed);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBarberCard(String name, String shopName, String address, bool isClaimed) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: ListTile(
        title: Text(name),
        subtitle: Text('$shopName\n$address'),
        trailing: Button(
          width: 150,
          onPressed: isClaimed ? null : () {
            showClaimDialog(name);
          },
          child: Text(
            isClaimed ? 'Already Claimed' : 'Claim Business',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
