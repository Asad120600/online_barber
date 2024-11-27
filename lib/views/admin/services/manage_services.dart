import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:online_barber_app/models/service_model.dart';
import 'package:online_barber_app/utils/button.dart';
import 'dart:io';
import 'package:online_barber_app/utils/loading_dialog.dart';
import 'package:online_barber_app/utils/loading_dots.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ManageService extends StatefulWidget {
  final Service? service;

  const ManageService({super.key, this.service});

  @override
  _ManageServiceState createState() => _ManageServiceState();
}

class _ManageServiceState extends State<ManageService> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _homeServicePriceController = TextEditingController();
  String _category = 'Hair Styles';
  File? _image;
  String? _imageUrl;
  bool _isHomeService = false;
  bool _isUploading = false; // New state to track the uploading process

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _priceController.text = widget.service!.price.toString();
      _homeServicePriceController.text = widget.service!.homeServicePrice.toString();
      _category = widget.service!.category;
      _imageUrl = widget.service!.imageUrl;
      _isHomeService = widget.service!.isHomeService;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    setState(() {
      _isUploading = true;  //Start showing loading indicator
    });

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference = FirebaseStorage.instance.ref().child('services/$fileName');
    UploadTask uploadTask = storageReference.putFile(image);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();

    setState(() {
      _isUploading = false;  // Hide loading indicator after upload
    });

    return downloadUrl;
  }

  void _saveService() async {
    if (_formKey.currentState!.validate()) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return LoadingDialog(message: AppLocalizations.of(context)!.service_added);
        },
      );

      String? imageUrl = _imageUrl;

      if (_image != null) {
        imageUrl = await _uploadImage(_image!);
      }

      // Here, you should provide a productId.
      // You can either generate it based on the service name or another logic.
      final service = Service(
        id: widget.service?.id ?? '',  // Provide an ID for both new and existing services
        name: _nameController.text,
        price: double.parse(_priceController.text),
        category: _category,
        imageUrl: imageUrl,
        isHomeService: _isHomeService,
        homeServicePrice: double.parse(_homeServicePriceController.text),
        productId: widget.service?.productId ?? _generateProductId(_nameController.text), // Generate productId
      );

      if (widget.service != null) {
        await FirebaseFirestore.instance
            .collection('services')
            .doc(service.id)
            .update(service.toMap());
      } else {
        final docRef = await FirebaseFirestore.instance
            .collection('services')
            .add(service.toMap());
        await FirebaseFirestore.instance
            .collection('services')
            .doc(docRef.id)
            .update({'id': docRef.id});
      }

      // Hide loading dialog
      Navigator.of(context).pop(); // Close the loading dialog

      Navigator.pop(context); // Close the ManageService screen
    }
  }

  String _generateProductId(String serviceName) {
    return serviceName.toLowerCase().replaceAll(' ', '_'); // Basic example of productId generation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service == null
            ? AppLocalizations.of(context)!.add_service
            : AppLocalizations.of(context)!.edit_service),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.service_name),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.service_name_required;
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.price),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.price_required;
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _homeServicePriceController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.home_service_price),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.home_service_price_required;
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: _category,
                    items: ['Hair Styles', 'Beard Styles'].map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _category = newValue!;
                      });
                    },
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.category),
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context)!.is_home_service),
                    value: _isHomeService,
                    onChanged: (bool? value) {
                      setState(() {
                        _isHomeService = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_image != null)
                    Image.file(
                      _image!,
                      height: 150,
                    )
                  else if (_imageUrl != null)
                    Image.network(
                      _imageUrl!,
                      height: 150,
                    ),
                  TextButton(
                    onPressed: _pickImage,
                    child: Text(AppLocalizations.of(context)!.pick_image),
                  ),
                  const SizedBox(height: 20),
                  if (_isUploading)
                    const LoadingDots(), // Show LoadingDots while uploading
                  const SizedBox(height: 20),
                  Button(
                    onPressed: _saveService,
                    child: Text(widget.service == null
                        ? AppLocalizations.of(context)!.add_service_button
                        : AppLocalizations.of(context)!.save_changes_button),
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
