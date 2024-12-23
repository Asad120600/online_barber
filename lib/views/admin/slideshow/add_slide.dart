import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  bool _isUploading = false;

  Future<void> _uploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        print('No image selected.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.no_image_selected)),
        );
        return;
      }

      print('Image selected: ${image.path}');
      final file = File(image.path);

      if (!await file.exists()) {
        print('File does not exist.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.file_does_not_exist)),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final fileName = DateTime.now().toIso8601String();
      final ref = _storage.ref().child('slideshow_images/$fileName');
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      setState(() {
        _imageFile = file;
        _imageUrl = imageUrl;
        _isUploading = false;
      });

      print('Image uploaded successfully: $imageUrl');
    } catch (e) {
      print('Error during image upload: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.upload_failed)),
      );

      setState(() {
        _isUploading = false;
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
        Navigator.of(context).pop(true);
      } catch (e) {
        print('Error saving slide: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.save_failed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.add_new_slide)),
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
                    const SizedBox(height: 10),
                    Text(AppLocalizations.of(context)!.image_selected),
                  ],
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.image_text,
                ),
              ),
              const SizedBox(height: 20),
              _isUploading
                  ? const LoadingDots()
                  : ElevatedButton.icon(
                onPressed: _uploadImage,
                icon: const Icon(Icons.image),
                label: Text(AppLocalizations.of(context)!.upload_image),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSlide,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                ),
                child: Text(AppLocalizations.of(context)!.save_slide),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
