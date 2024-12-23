import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClaimRequestsScreen extends StatefulWidget {
  const ClaimRequestsScreen({super.key});

  @override
  State<ClaimRequestsScreen> createState() => _ClaimRequestsScreenState();
}

class _ClaimRequestsScreenState extends State<ClaimRequestsScreen> with SingleTickerProviderStateMixin {
  final CollectionReference claimsRef = FirebaseFirestore.instance.collection('claim_business');
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Approve a business claim
  Future<void> approveClaim(String claimId) async {
    await claimsRef.doc(claimId).update({'status': 'approved'});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.claim_approved)),
    );
  }

  // Disapprove a business claim
  Future<void> disapproveClaim(String claimId) async {
    await claimsRef.doc(claimId).update({'status': 'disapproved'});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.claim_disapproved)),
    );
  }

  // View barber details dialog
  void showClaimDetails(Map<String, dynamic> claimData) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${localizations.claim_details}: ${claimData['barberName']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${localizations.shop_name}: ${claimData['shopName']}'),
                Text('${localizations.address}: ${claimData['address']}'),
                Text('${localizations.phone}: ${claimData['phoneNumber']}'),
                Text('${localizations.email}: ${claimData['email']}'),
                Text('${localizations.national_id}: ${claimData['nationalId']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.close),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.claim_requests),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: localizations.pending_requests),
              Tab(text: localizations.approved_requests),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Pending Requests Tab
            StreamBuilder<QuerySnapshot>(
              stream: claimsRef.where('status', isEqualTo: 'pending').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text(localizations.no_pending_claims));
                }

                final claims = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: claims.length,
                  itemBuilder: (context, index) {
                    var claim = claims[index];
                    var claimData = claim.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(claimData['barberName'] ?? localizations.no_name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${localizations.shop_name}: ${claimData['shopName']}'),
                            Text('${localizations.address}: ${claimData['address']}'),
                            Text('${localizations.phone}: ${claimData['phoneNumber']}'),
                            Text('${localizations.email}: ${claimData['email']}'),
                            Text('${localizations.national_id}: ${claimData['nationalId']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => approveClaim(claim.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => disapproveClaim(claim.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            // Approved Requests Tab
            StreamBuilder<QuerySnapshot>(
              stream: claimsRef.where('status', isEqualTo: 'approved').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text(localizations.no_approved_claims));
                }

                final claims = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: claims.length,
                  itemBuilder: (context, index) {
                    var claim = claims[index];
                    var claimData = claim.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(claimData['barberName'] ?? localizations.no_name),
                        subtitle: Text('${localizations.shop_name}: ${claimData['shopName']}'),
                        onTap: () => showClaimDetails(claimData),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}