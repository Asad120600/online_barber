import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:online_barber_app/utils/loading_dots.dart';

class AddSlidePage extends StatefulWidget {
  const AddSlidePage({super.key});

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
  bool _isUploading = false; // State to track the upload status

  Future<void> _uploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        print('No image selected.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No image selected')),
        );
        return;
      }

      print('Image selected: ${image.path}');
      final file = File(image.path);

      if (!await file.exists()) {
        print('File does not exist.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File does not exist')),
        );
        return;
      }

      setState(() {
        _isUploading = true; // Start showing the loading indicator
      });

      final fileName = DateTime.now().toIso8601String();
      final ref = _storage.ref().child('slideshow_images/$fileName');
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      setState(() {
        _imageFile = file;
        _imageUrl = imageUrl;
        _isUploading = false; // Hide loading indicator after upload
      });

      print('Image uploaded successfully: $imageUrl');
    } catch (e) {
      print('Error during image upload: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image')),
      );

      setState(() {
        _isUploading = false; // Hide loading indicator if upload fails
      });
    }
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
              _isUploading
                  ? LoadingDots() // Show LoadingDots widget while uploading
                  : ElevatedButton.icon(
                onPressed: _uploadImage,
                icon: Icon(Icons.image),
                label: Text('Upload Image'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSlide,
                child: Text('Save Slide'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
