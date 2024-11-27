import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:online_barber_app/views/admin/slideshow/add_slide.dart';
import 'package:online_barber_app/views/admin/slideshow/edit_slide.dart';

class AdminSlideshowScreen extends StatefulWidget {
  const AdminSlideshowScreen({super.key});

  @override
  _AdminSlideshowScreenState createState() => _AdminSlideshowScreenState();
}

class _AdminSlideshowScreenState extends State<AdminSlideshowScreen> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _slides = [];

  @override
  void initState() {
    super.initState();
    _fetchSlides();
  }

  Future<void> _fetchSlides() async {
    try {
      final snapshot = await _firestore.collection('slideshow_images').get();
      final slides = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'imageUrl': doc['imageUrl'],
          'text': doc['text'],
        };
      }).toList();
      setState(() {
        _slides = slides;
      });
    } catch (e) {
      print('Error fetching slides: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failed_to_load_slides)),
      );
    }
  }

  Future<void> _deleteSlide(String documentId, String imageUrl) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirm_delete),
          content: Text(AppLocalizations.of(context)!.delete_confirmation_message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Delete image from storage
                  final ref = _storage.refFromURL(imageUrl);
                  await ref.delete();

                  // Delete document from Firestore
                  await _firestore.collection('slideshow_images').doc(documentId).delete();

                  _fetchSlides(); // Refresh the list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.slide_deleted_successfully)),
                  );
                } catch (e) {
                  print('Error deleting slide: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.failed_to_delete_slide)),
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.manage_slideshow_images)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AddSlidePage(),
                    )).then((_) {
                      _fetchSlides(); // Refresh the list after returning
                    });
                  },
                  child: Text(AppLocalizations.of(context)!.add_new_slide),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange,
                  ),
                ),
                SizedBox(height: 20),
                if (_slides.isNotEmpty) ...[
                  ..._slides.map((slide) {
                    return ListTile(
                      leading: Image.network(slide['imageUrl'], width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(slide['text']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => EditSlidePage(
                                  documentId: slide['id'],
                                  imageUrl: slide['imageUrl'],
                                  initialText: slide['text'],
                                ),
                              )).then((_) {
                                _fetchSlides(); // Refresh the list after returning
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteSlide(slide['id'], slide['imageUrl']),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ] else
                  Text(AppLocalizations.of(context)!.no_slides_available),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
