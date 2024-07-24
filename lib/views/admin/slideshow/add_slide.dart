import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddSlidePage extends StatefulWidget {
  const AddSlidePage({Key? key}) : super(key: key);

  @override
  _AddSlidePageState createState() => _AddSlidePageState();
}

class _AddSlidePageState extends State<AddSlidePage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  String? _imageUrl;
  File? _imageFile;

  Future<void> _uploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final file = File(image.path);
    final fileName = DateTime.now().toIso8601String();
    final ref = _storage.ref().child('slideshow_images/$fileName');
    await ref.putFile(file);
    final imageUrl = await ref.getDownloadURL();

    setState(() {
      _imageFile = file;
      _imageUrl = imageUrl;
    });
  }

  Future<void> _saveSlide() async {
    if (_imageUrl != null && _textController.text.isNotEmpty) {
      try {
        await _firestore.collection('slideshow_images').add({
          'imageUrl': _imageUrl!,
          'text': _textController.text,
        });
        Navigator.of(context).pop(true); // Return to previous page with success
      } catch (e) {
        print('Error saving slide: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save slide')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Slide')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_imageUrl != null)
                Column(
                  children: [
                    Image.network(_imageUrl!),
                    SizedBox(height: 10),
                    Text('Image selected'),
                  ],
                ),
              SizedBox(height: 20),
              TextField(
                controller: _textController,
                decoration: InputDecoration(labelText: 'Image Text'),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _uploadImage,
                icon: Icon(Icons.image),
                label: Text('Upload Image'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.orange,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSlide,
                child: Text('Save Slide'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
