import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../../../controllers/barber_service.dart';
import '../../../models/barber_model.dart';
import '../../../utils/button.dart';

class ManageBarbersScreen extends StatefulWidget {
  @override
  _ManageBarbersScreenState createState() => _ManageBarbersScreenState();
}

class _ManageBarbersScreenState extends State<ManageBarbersScreen> {
  final _formKey = GlobalKey<FormState>();
  final BarberService _barberService = BarberService();
  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final Uuid _uuid = Uuid();
  File? _imageFile;

  void _addBarber() async {
    if (_formKey.currentState!.validate()) {
      String imageUrl = '';

      if (_imageFile != null) {
        // Upload image and get the URL
        imageUrl = await _barberService.uploadImage(_imageFile!);
      }

      final barber = Barber(
        id: _uuid.v4(),
        name: _nameController.text,
        phoneNumber: _phoneNumberController.text,
        address: _addressController.text,
        imageUrl: imageUrl,
      );
      await _barberService.addBarber(barber);
      _clearForm();
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneNumberController.clear();
    _addressController.clear();
    setState(() {
      _imageFile = null;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Barbers'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter a name' : null,
                    ),
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: InputDecoration(labelText: 'Phone Number'),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter a phone number' : null,
                    ),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(labelText: 'Address'),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter an address' : null,
                    ),
                    SizedBox(height: 20),
                    _imageFile == null
                        ? Text('No image selected.')
                        : Image.file(_imageFile!, height: 100),
                    SizedBox(height: 20),
                    IconButton(
                      onPressed: _pickImage,
                      icon:Icon(Icons.image),
                      iconSize: 35,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 20),
                    Button(
                      onPressed: _addBarber,
                      child: Text('Add Barber'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              StreamBuilder<List<Barber>>(
                stream: _barberService.getBarbers(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final barbers = snapshot.data ?? [];

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: barbers.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: barbers[index].imageUrl.isEmpty
                            ? CircleAvatar(
                          child: Icon(Icons.person),
                        )
                            : CircleAvatar(
                          backgroundImage:
                          NetworkImage(barbers[index].imageUrl),
                        ),
                        title: Text(barbers[index].name),
                        subtitle: Text(barbers[index].phoneNumber),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _barberService.removeBarber(barbers[index].id);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
