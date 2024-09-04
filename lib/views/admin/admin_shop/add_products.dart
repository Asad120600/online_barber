import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/utils/button.dart';
import 'package:online_barber_app/utils/loading_dialog.dart';
import 'package:online_barber_app/views/admin/admin_panel.dart';

class AddProducts extends StatefulWidget {
  const AddProducts({super.key});

  @override
  _AddProductsState createState() => _AddProductsState();
}

class _AddProductsState extends State<AddProducts> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  XFile? _imageFile;
  String _imageUrl = '';
  String _price = '';
  String _description = '';
  String _productName = ''; // Variable for product name

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile != null) {
      final storageRef = FirebaseStorage.instance.ref().child('product_images').child(_imageFile!.name);
      await storageRef.putFile(File(_imageFile!.path));
      final url = await storageRef.getDownloadURL();
      setState(() {
        _imageUrl = url;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      // Show the loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const LoadingDialog(
          message: 'Product is adding....',
        ),
      );

      try {
        if (_imageFile != null) {
          await _uploadImage();
        }

        await FirebaseFirestore.instance.collection('products').add({
          'imageUrl': _imageUrl,
          'price': _price,
          'description': _description,
          'productName': _productName, // Save product name
        });

        // Hide the loading dialog after successful upload
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product added')));

        // Show success dialog and redirect
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Success'),
            content: Text('Product added successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => AdminPanel(), // Navigate to AdminPanel
                  ));
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        // Hide the loading dialog in case of an error
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add product: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Product Management')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: _imageFile == null
                          ? Center(child: Text('Pick Image'))
                          : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Product Name'), // Add product name field
                    onChanged: (value) => _productName = value,
                    validator: (value) => value!.isEmpty ? 'Please enter a product name' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _price = value,
                    validator: (value) => value!.isEmpty ? 'Please enter a price' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Description'),
                    onChanged: (value) => _description = value,
                    validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                  ),
                  SizedBox(height: 85),
                  Center(
                    child: Button(
                      width: 150,
                      onPressed: _saveProduct,
                      child: Text('Save Product'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
