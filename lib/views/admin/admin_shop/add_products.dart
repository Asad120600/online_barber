import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  String _productName = '';

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
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child(_imageFile!.name);
      await storageRef.putFile(File(_imageFile!.path));
      final url = await storageRef.getDownloadURL();
      setState(() {
        _imageUrl = url;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => LoadingDialog(
          message: AppLocalizations.of(context)!.addingProduct,
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
          'productName': _productName,
        });

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.productAdded)),
        );

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.success),
            content: Text(AppLocalizations.of(context)!.productAddedSuccessfully),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const AdminPanel(),
                  ));
                },
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        );
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToAddProduct(e.toString()),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.adminProductManagement)),
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
                          ? Center(child: Text(AppLocalizations.of(context)!.pickImage))
                          : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.productName,
                    ),
                    onChanged: (value) => _productName = value,
                    validator: (value) =>
                    value!.isEmpty ? AppLocalizations.of(context)!.enterProductName : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.price,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _price = value,
                    validator: (value) =>
                    value!.isEmpty ? AppLocalizations.of(context)!.enterPrice : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.description,
                    ),
                    onChanged: (value) => _description = value,
                    validator: (value) =>
                    value!.isEmpty ? AppLocalizations.of(context)!.enterDescription : null,
                  ),
                  const SizedBox(height: 85),
                  Center(
                    child: Button(
                      width: 165,
                      onPressed: _saveProduct,
                      child: Text(AppLocalizations.of(context)!.saveProduct),
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
