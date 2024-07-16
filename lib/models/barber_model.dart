import 'package:cloud_firestore/cloud_firestore.dart';

class Barber {

  final String id;
  final String name;
  final String phoneNumber;
  final String address;
  final String imageUrl;
  String email;
  String userType;

  Barber({
    required this.email,
    required this.userType,
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.imageUrl,
  });

  factory Barber.fromSnapshot(DocumentSnapshot doc) {
    return Barber(
      id: doc['id'] ?? '',
      name: doc['name'] ?? '',
      email: doc['email'] ?? '',
      phoneNumber: doc['phoneNumber'] ?? '',
      address: doc['address'] ?? '',
      imageUrl: doc['imageUrl'] ?? '',
      userType: doc['userType'] ?? '3',


    );
  }

  factory Barber.fromMap(Map<String, dynamic> data) {
    return Barber(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      email: data['email'] ?? '',
      userType: data['userType'] ?? '3',


    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'imageUrl': imageUrl,
      'email':email,
      'userType':userType,

    };
  }
}

// class BarberScreen extends StatefulWidget {
//   @override
//   _BarberScreenState createState() => _BarberScreenState();
// }
//
// class _BarberScreenState extends State<BarberScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Future<List<Barber>> _getBarbers() async {
//     QuerySnapshot snapshot = await _firestore.collection('barbers').get();
//     return snapshot.docs.map((doc) => Barber.fromSnapshot(doc)).toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Barbers'),
//       ),
//       body: FutureBuilder<List<Barber>>(
//         future: _getBarbers(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(child: Text('No barbers found'));
//           } else {
//             return ListView.builder(
//               itemCount: snapshot.data!.length,
//               itemBuilder: (context, index) {
//                 Barber barber = snapshot.data![index];
//                 return ListTile(
//                   leading: barber.imageUrl.isNotEmpty
//                       ? Image.network(barber.imageUrl)
//                       : null,
//                   title: Text(barber.name),
//                   subtitle: Text(barber.phoneNumber),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => BarberDetailScreen(barber: barber),
//                       ),
//                     );
//                   },
//                 );
//               },
//             );
//           }
//         },
//       ),
//     );
//   }
// }
//
// class BarberDetailScreen extends StatelessWidget {
//   final Barber barber;
//
//   BarberDetailScreen({required this.barber});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(barber.name),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             barber.imageUrl.isNotEmpty
//                 ? Image.network(barber.imageUrl)
//                 : Container(),
//             SizedBox(height: 16.0),
//             Text('Name: ${barber.name}', style: TextStyle(fontSize: 18.0)),
//             SizedBox(height: 8.0),
//             Text('Phone: ${barber.phoneNumber}', style: TextStyle(fontSize: 18.0)),
//             SizedBox(height: 8.0),
//             Text('Address: ${barber.address}', style: TextStyle(fontSize: 18.0)),
//           ],
//         ),
//       ),
//     );
//   }
// }
