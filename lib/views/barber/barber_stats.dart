import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Stats extends StatefulWidget {
  final String barberId;

  const Stats({super.key, required this.barberId});

  @override
  State<Stats> createState() => _StatsState();
}

class _StatsState extends State<Stats> {
  late Future<Map<String, double>> _earningsFuture;

  @override
  void initState() {
    super.initState();
    _earningsFuture = _fetchEarnings(widget.barberId);
  }

  Future<Map<String, double>> _fetchEarnings(String barberId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!; // Get localized strings

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.barberStats),
        elevation: 4.0,
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _earningsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(localizations.errorLoadingData));
          }

          Map<String, double> earnings = snapshot.data ?? {};
          List<String> lastThreeMonths = _getLastThreeMonths();

          for (String month in lastThreeMonths) {
            if (!earnings.containsKey(month)) {
              earnings[month] = 0.0;
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.earningsLastThreeMonths,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                if (earnings.isEmpty)
                  Center(
                    child: Text(
                      localizations.noEarningsData,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                else
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1.5,
                      child: BarberEarningsChart(earnings: earnings),
                    ),
                  ),
                const SizedBox(height: 20),
                if (earnings.isNotEmpty) CommissionDisplay(earnings: earnings),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _getLastThreeMonths() {
    DateTime now = DateTime.now();
    return List.generate(3, (index) {
      DateTime date = DateTime(now.year, now.month - index, 1);
      return DateFormat.yMMMM().format(date);
    }).reversed.toList();
  }
}

class BarberEarningsChart extends StatelessWidget {
  final Map<String, double> earnings;

  const BarberEarningsChart({super.key, required this.earnings});

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> barGroups = [];

    int index = 0;
    earnings.forEach((month, amount) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: Colors.orange,
              borderRadius: BorderRadius.circular(4),
              width: MediaQuery.of(context).size.width * 0.06,
              backDrawRodData: BackgroundBarChartRodData(
                toY: 0,
                color: Colors.grey.shade300,
                show: true,
              ),
            ),
          ],
        ),
      );
      index++;
    });

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: earnings.values.isNotEmpty
                  ? (earnings.values.reduce((a, b) => a > b ? a : b) / 5).clamp(1, double.infinity)
                  : 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    earnings.keys.elementAt(value.toInt()),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }
}

class CommissionDisplay extends StatelessWidget {
  final Map<String, double> earnings;

  const CommissionDisplay({super.key, required this.earnings});

  @override
  Widget build(BuildContext context) {
    double totalEarnings = earnings.values.reduce((a, b) => a + b);
    double commission = totalEarnings * 0.10;

    final localizations = AppLocalizations.of(context)!; // Get localized strings

    return Center(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              localizations.totalEarnings(totalEarnings.toStringAsFixed(2)),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              localizations.commission(commission.toStringAsFixed(2)),
              style: const TextStyle(
                fontSize: 20,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
