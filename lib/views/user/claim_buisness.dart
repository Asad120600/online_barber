import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:online_barber_app/utils/claim_buisness_user_dialog.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import for localization

class ClaimBusiness extends StatefulWidget {
  const ClaimBusiness({super.key});

  @override
  State<ClaimBusiness> createState() => _ClaimBusinessState();
}

class _ClaimBusinessState extends State<ClaimBusiness> {
  final CollectionReference barbersRef = FirebaseFirestore.instance.collection('barbers');
  final CollectionReference claimsRef = FirebaseFirestore.instance.collection('claim_business');
  String? adminUid;

  @override
  void initState() {
    super.initState();
    fetchAdminUid();
  }

  Future<void> fetchAdminUid() async {
    try {
      var adminSnapshot = await FirebaseFirestore.instance.collection('admins').limit(1).get();
      if (adminSnapshot.docs.isNotEmpty) {
        setState(() {
          adminUid = adminSnapshot.docs.first.id;
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
            onSubmit: (String barberName, String shopName, String address,
                String phoneNumber, String email, String nationalId) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.claimSubmitted(barberName),)),
              );
            },
            adminUid: adminUid!,
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorFetchingAdminUid)),
      );
    }
  }

  Future<void> _refreshBarbers() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations!.claimBusiness)),
      body: RefreshIndicator(
        onRefresh: _refreshBarbers,
        child: StreamBuilder<QuerySnapshot>(
          stream: barbersRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LoadingDots());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text(localizations.noBarbersAvailable));
            }

            final barbers = snapshot.data!.docs;

            return ListView.builder(
              itemCount: barbers.length,
              itemBuilder: (context, index) {
                var barber = barbers[index];
                var name = barber['name'] ?? localizations.noName;
                var shopName = barber['shopName'] ?? localizations.noShopName;
                var address = barber['address'] ?? localizations.noAddress;

                return FutureBuilder<bool>(
                  future: isBusinessClaimed(name),
                  builder: (context, claimedSnapshot) {
                    bool isClaimed = claimedSnapshot.data ?? false;
                    return _buildBarberCard(name, shopName, address, isClaimed, localizations);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBarberCard(String name, String shopName, String address, bool isClaimed, AppLocalizations localizations) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: ListTile(
        title: Text(name),
        subtitle: Text('$shopName\n$address'),
        trailing: Button(
          width: 150,
          onPressed: isClaimed
              ? null
              : () {
            showClaimDialog(name);
          },
          child: Text(
            isClaimed ? localizations.alreadyClaimed : localizations.claimBusinessButton,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
