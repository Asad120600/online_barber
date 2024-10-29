import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClaimRequestsScreen extends StatefulWidget {
  const ClaimRequestsScreen({Key? key}) : super(key: key);

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
      const SnackBar(content: Text('Claim approved successfully!')),
    );
  }

  // Disapprove a business claim
  Future<void> disapproveClaim(String claimId) async {
    await claimsRef.doc(claimId).update({'status': 'disapproved'});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Claim disapproved successfully!')),
    );
  }

  // View barber details dialog
  void showClaimDetails(Map<String, dynamic> claimData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Claim Details: ${claimData['barberName']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shop Name: ${claimData['shopName']}'),
                Text('Address: ${claimData['address']}'),
                Text('Phone: ${claimData['phoneNumber']}'),
                Text('Email: ${claimData['email']}'),
                Text('National ID: ${claimData['nationalId']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Claim Requests'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Pending Requests'),
              Tab(text: 'Approved Requests'),
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
                  return const Center(child: Text("No pending claims available"));
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
                        title: Text(claimData['barberName'] ?? 'No Name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Shop Name: ${claimData['shopName']}'),
                            Text('Address: ${claimData['address']}'),
                            Text('Phone: ${claimData['phoneNumber']}'),
                            Text('Email: ${claimData['email']}'),
                            Text('National ID: ${claimData['nationalId']}'),
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
                  return const Center(child: Text("No approved claims available"));
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
                        title: Text(claimData['barberName'] ?? 'No Name'),
                        subtitle: Text('Shop Name: ${claimData['shopName']}'),
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
