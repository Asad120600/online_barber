import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load slides')));
    }
  }

  Future<void> _deleteSlide(String documentId, String imageUrl) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this slide?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Slide deleted successfully')));
                } catch (e) {
                  print('Error deleting slide: $e');
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete slide')));
                }
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Slideshow Images')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AddSlidePage(), // Navigate to AddSlidePage
                    )).then((_) {
                      _fetchSlides(); // Refresh the list after returning
                    });
                  },
                  child: Text('Add New Slide'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.orange, // Text color
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
                  Text('No slides available'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
