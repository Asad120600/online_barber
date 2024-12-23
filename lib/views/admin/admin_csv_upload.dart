import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/models/barber_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminCsvUploadPage extends StatefulWidget {
  const AdminCsvUploadPage({super.key});

  @override
  _AdminCsvUploadPageState createState() => _AdminCsvUploadPageState();
}

class _AdminCsvUploadPageState extends State<AdminCsvUploadPage> {
  bool _isUploading = false;
  double _progress = 0.0;
  List<List<dynamic>>? _previewData;
  final List<Map<String, dynamic>> _uploadedCsvs = [];

  @override
  void initState() {
    super.initState();
    _loadUploadedCsvs();  // Load previously uploaded CSVs from SharedPreferences
  }

  Future<void> _loadUploadedCsvs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Set<String> keys = prefs.getKeys();

    for (var key in keys) {
      var storedCsv = prefs.get(key);

      if (storedCsv is String) {
        final List<List<dynamic>> rows = const CsvToListConverter().convert(storedCsv);

        _uploadedCsvs.add({
          'fileName': key,
          'data': rows,
        });
      } else {
        print('Skipping non-string value for key: $key');
      }
    }

    setState(() {});
  }

  Future<void> _pickAndUploadCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      _uploadCSV(file);
    }
  }

  Future<void> _uploadCSV(File file) async {
    setState(() {
      _isUploading = true;
      _progress = 0.0;
    });

    try {
      final input = await file.readAsString();
      final List<List<dynamic>> rows = const CsvToListConverter().convert(input);

      setState(() {
        _previewData = rows;
      });

      for (var i = 1; i < rows.length; i++) {
        List<dynamic> row = rows[i];

        try {
          UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: row[2].toString(),
            password: '12345678',
          );

          Barber barber = Barber(
            id: userCredential.user?.uid ?? row[0].toString(),
            address: row[1].toString(),
            email: row[2].toString(),
            imageUrl: row[3].toString(),
            latitude: double.parse(row[4].toString()),
            longitude: double.parse(row[5].toString()),
            name: row[6].toString(),
            phoneNumber: row[7].toString(),
            rating: double.parse(row[8].toString()),
            ratingCount: int.parse(row[9].toString()),
            shopName: row[10].toString(),
            token: row[11].toString(),
            userType: row[12].toString(), // You can remove this if not needed
          );

          await FirebaseFirestore.instance
              .collection('barbers')
              .doc(barber.id)
              .set(barber.toMap());
        } catch (authError) {
          print("Auth error for ${row[2]}: $authError");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to add ${row[6]}: ${authError.toString()}")),
          );
        }

        setState(() {
          _progress = i / (rows.length - 1);
        });
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String fileName = file.path.split('/').last;
      await prefs.setString(fileName, input);

      _uploadedCsvs.add({
        'fileName': fileName,
        'data': _previewData,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV uploaded successfully!')),
      );
    } catch (e) {
      print("Error uploading CSV: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload CSV')),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _progress = 0.0;
      });
    }
  }

  void _showPreviewDialog(String fileName, List<List<dynamic>> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("File: $fileName"),
            ],
          ),
          content: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: data[0].map((col) => DataColumn(label: Text(col.toString()))).toList(),
              rows: data.skip(1).map((row) {
                return DataRow(
                  cells: row.map((cell) => DataCell(Text(cell.toString()))).toList(),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildUploadedCsvList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _uploadedCsvs.length,
      itemBuilder: (context, index) {
        final fileInfo = _uploadedCsvs[index];
        return ListTile(
          title: Text(fileInfo['fileName']),
          subtitle: Text("Uploaded on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}"),
          onTap: () {
            _showPreviewDialog(fileInfo['fileName'], fileInfo['data']);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Barber CSV"),
      ),
      body: Center(
        child: _isUploading
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(value: _progress),
            const SizedBox(height: 20),
            Text("${(_progress * 100).toStringAsFixed(1)}%"),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickAndUploadCSV,
              child: const Text("Upload CSV"),
            ),
            const SizedBox(height: 20),
            const Text("Recently Uploaded CSVs"),
            Expanded(child: _buildUploadedCsvList()),
          ],
        ),
      ),
    );
  }
}
