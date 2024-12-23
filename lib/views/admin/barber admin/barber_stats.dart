import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:online_barber_app/models/barber_model.dart';

class BarberStatsScreen extends StatefulWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BarberStatsScreen({super.key});

  @override
  _BarberStatsScreenState createState() => _BarberStatsScreenState();
}

class _BarberStatsScreenState extends State<BarberStatsScreen> {
  Future<void> _refreshBarbers() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.barber_stats),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: widget._firestore.collection('barbers').snapshots(),
        builder: (context, barberSnapshot) {
          if (barberSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!barberSnapshot.hasData || barberSnapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.no_barbers_found),
            );
          }

          List<Barber> barbers = barberSnapshot.data!.docs
              .map((doc) => Barber.fromSnapshot(doc))
              .toList();

          return RefreshIndicator(
            onRefresh: _refreshBarbers,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: barbers.length,
              itemBuilder: (context, index) {
                Barber barber = barbers[index];

                return GestureDetector(
                  onTap: () => _showTotalPricesDialog(context, barber.id),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: FutureBuilder<int>(
                        future: _getDoneAppointmentsCount(barber.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListTile(
                              title: Text(AppLocalizations.of(context)!.loading),
                            );
                          }

                          if (snapshot.hasError) {
                            return ListTile(
                              title: Text(barber.name),
                              subtitle: Text(
                                AppLocalizations.of(context)!
                                    .error_loading_appointments,
                              ),
                              trailing: const Icon(
                                Icons.error,
                                color: Colors.red,
                              ),
                            );
                          }

                          int doneAppointmentsCount = snapshot.data ?? 0;

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.orange,
                              child: CircleAvatar(
                                radius: 27,
                                backgroundImage: barber.imageUrl.isNotEmpty
                                    ? NetworkImage(barber.imageUrl)
                                    : null,
                                backgroundColor: barber.imageUrl.isEmpty
                                    ? Colors.orange
                                    : Colors.transparent,
                                child: barber.imageUrl.isEmpty
                                    ? const Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Colors.white,
                                )
                                    : null,
                              ),
                            ),
                            title: Text(
                              barber.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                            subtitle: Text(
                              '${AppLocalizations.of(context)!.done_appointments}: $doneAppointmentsCount',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<int> _getDoneAppointmentsCount(String barberId) async {
    QuerySnapshot querySnapshot = await widget._firestore
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .where('status', isEqualTo: 'Done')
        .get();

    return querySnapshot.docs.length;
  }

  void _showTotalPricesDialog(BuildContext context, String barberId) async {
    Map<String, double> monthlyTotals = await _getTotalPricesByMonth(barberId);

    DateTime now = DateTime.now();
    List<String> lastThreeMonths = List.generate(3, (index) {
      DateTime date = DateTime(now.year, now.month - index, 1);
      return DateFormat.yMMMM().format(date);
    });

    String currentMonth = lastThreeMonths.first;
    double currentMonthEarnings = monthlyTotals[currentMonth] ?? 0.0;
    double currentMonthCommission = currentMonthEarnings * 0.1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.total_prices),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.select_month,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: currentMonth,
                    items: lastThreeMonths.map((String month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    onChanged: (String? newMonth) {
                      setState(() {
                        currentMonth = newMonth!;
                        currentMonthEarnings =
                            monthlyTotals[currentMonth] ?? 0.0;
                        currentMonthCommission = currentMonthEarnings * 0.1;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                      '${AppLocalizations.of(context)!.earnings_for} $currentMonth:'),
                  Text(
                    currentMonthEarnings.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                      '${AppLocalizations.of(context)!.commission_for} $currentMonth:'),
                  Text(
                    currentMonthCommission.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(AppLocalizations.of(context)!.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, double>> _getTotalPricesByMonth(String barberId) async {
    QuerySnapshot querySnapshot = await widget._firestore
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .where('status', isEqualTo: 'Done')
        .get();

    Map<String, double> monthlyTotals = {};

    for (var doc in querySnapshot.docs) {
      double price = doc['totalPrice'] ?? 0.0;
      DateTime date = (doc['date'] as Timestamp).toDate();
      String month = DateFormat.yMMMM().format(date);

      if (monthlyTotals.containsKey(month)) {
        monthlyTotals[month] = monthlyTotals[month]! + price;
      } else {
        monthlyTotals[month] = price;
      }
    }

    return monthlyTotals;
  }
}
