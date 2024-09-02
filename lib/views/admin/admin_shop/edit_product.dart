import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_barber_app/utils/button.dart';

class EditProductPage extends StatefulWidget {
  final String productId;

  const EditProductPage({super.key, required this.productId});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  XFile? _imageFile;
  String _imageUrl = '';
  String _price = '';
  String _description = '';

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

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile != null) {
        await _uploadImage();
      }
      await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
        'imageUrl': _imageFile != null ? _imageUrl : FieldValue.delete(),
        'price': _price,
        'description': _description,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product updated')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Product')),
      body: SingleChildScrollView(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('products').doc(widget.productId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
        
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
        
            if (!snapshot.hasData) {
              return Center(child: Text('No data found'));
            }
        
            final product = snapshot.data!.data() as Map<String, dynamic>;
            _imageUrl = product['imageUrl'] ?? '';
            _price = product['price'] ?? '';
            _description = product['description'] ?? '';
        
            return Padding(
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
                            ? (product['imageUrl'] != null ? Image.network(product['imageUrl'], fit: BoxFit.cover) : Center(child: Text('Pick Image')))
                            : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: _price,
                      decoration: InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _price = value,
                      validator: (value) => value!.isEmpty ? 'Please enter a price' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: _description,
                      decoration: InputDecoration(labelText: 'Description'),
                      onChanged: (value) => _description = value,
                      validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                    ),
                    SizedBox(height: 85),
                    Center(
                      child: Button(
                        width: 150,
                        onPressed: _updateProduct,
                        child: Text('Update Product'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
