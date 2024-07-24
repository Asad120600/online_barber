import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditSlidePage extends StatefulWidget {
  final String? documentId;
  final String? imageUrl;
  final String? initialText;

  const EditSlidePage({Key? key, this.documentId, this.imageUrl, this.initialText}) : super(key: key);

  @override
  _EditSlidePageState createState() => _EditSlidePageState();
}

class _EditSlidePageState extends State<EditSlidePage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  String? _imageUrl;
  String? _imageName;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.imageUrl;
    _textController.text = widget.initialText ?? '';
  }

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
      _imageName = file.uri.pathSegments.last; // Get image file name
    });
  }

  Future<void> _saveData() async {
    if (_imageUrl != null && _textController.text.isNotEmpty) {
      try {
        if (widget.documentId == null) {
          // Add new slide
          await _firestore.collection('slideshow_images').add({
            'imageUrl': _imageUrl!,
            'text': _textController.text,
          });
        } else {
          // Update existing slide
          if (_imageFile != null) {
            final fileName = DateTime.now().toIso8601String();
            final ref = _storage.ref().child('slideshow_images/$fileName');
            await ref.putFile(_imageFile!);
            final newImageUrl = await ref.getDownloadURL();

            await _firestore.collection('slideshow_images').doc(widget.documentId).update({
              'imageUrl': newImageUrl,
              'text': _textController.text,
            });
          } else {
            await _firestore.collection('slideshow_images').doc(widget.documentId).update({
              'text': _textController.text,
            });
          }
        }

        Navigator.of(context).pop(true); // Return to previous page with success
      } catch (e) {
        print('Error saving data: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save data')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Slide')),
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
                    if (_imageName != null)
                      Text('Image Name: $_imageName'),
                  ],
                ),
              SizedBox(height: 20),
              TextField(
                controller: _textController,
                decoration: InputDecoration(labelText: 'Image Text'),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _uploadImage,
                  icon: Icon(Icons.image),
                  label: Text('Change Image'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.orange, // Text color
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _saveData,
                  child: Text('Save'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.orange, // Text color
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
