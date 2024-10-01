import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';

class BuyerForm extends StatefulWidget {
  final String email;

  BuyerForm({required this.email});

  @override
  _BuyerFormState createState() => _BuyerFormState();
}

class _BuyerFormState extends State<BuyerForm> {
  final _formKey = GlobalKey<FormState>();
  final databaseRef = FirebaseDatabase.instance.ref("buyers");
  final List<File> _images = [];

  bool _isLoading = false; // Loading state

  String fullName = '';
  String phone = '';
  String email = '';
  String address = '';
  String itemName = '';
  String itemCost = '';
  String description = '';
  String selectedCurrency = 'ETB'; // Default currency
  String selectedPaymentMethod = 'Cash'; // Default payment method
  int status = 0; // Default status
  double? latitude;
  double? longitude;

  List<String> currencies = ['ETB', 'USD', 'EUR', 'GBP', 'JPY'];
  List<String> paymentMethods = [
    'Cash',
    'Bank Transfer',
    'Credit Card',
    'No Matter'
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Get current location on init
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Handle permission denial
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _images.clear();
        for (var file in pickedFiles) {
          _images.add(File(file.path));
        }
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    for (var image in _images) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref =
          FirebaseStorage.instance.ref().child("itemPhotos/$fileName");
      await ref.putFile(image);
      String downloadUrl = await ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }
    return imageUrls;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true; // Start loading
      });

      List<String> imageUrls = await _uploadImages();

      await databaseRef.push().set({
        'fullName': fullName,
        'phone': phone,
        'email': widget.email,
        'address': address,
        'itemName': itemName,
        'itemCost': itemCost.replaceAll(',', ''), // Remove commas for storage
        'itemPhoto': imageUrls,
        'description': description,
        'currency': selectedCurrency,
        'paymentMethod': selectedPaymentMethod,
        'status': status, // Add status to database
        'userEmail': widget.email,
        'latitude': latitude, // Add latitude
        'longitude': longitude, // Add longitude
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request submitted successfully!')));

      _formKey.currentState!.reset();
      setState(() {
        _images.clear();
        _isLoading = false; // End loading
      });
    }
  }

  String formatCost(String value) {
    final number = double.tryParse(value.replaceAll(',', '')) ?? 0;
    return number.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => "${m[1]},",
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buyer Request Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  label: 'Full Name',
                  icon: Icons.person,
                  onSaved: (value) => fullName = value!,
                ),
                _buildTextField(
                  label: 'Phone',
                  icon: Icons.phone,
                  onSaved: (value) => phone = value!,
                ),
                _buildTextField(
                  label: 'Email',
                  icon: Icons.email,
                  onSaved: (value) => email = value!,
                  validator: (value) => value!.isEmpty ||
                          !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)
                      ? 'Please enter a valid email'
                      : null,
                ),
                _buildTextField(
                  label: 'Address',
                  icon: Icons.home,
                  onSaved: (value) => address = value!,
                ),
                _buildTextField(
                  label: 'Item Name',
                  icon: Icons.inventory,
                  onSaved: (value) => itemName = value!,
                ),
                _buildTextField(
                  label: 'Expected Item Cost',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      itemCost = formatCost(value);
                    });
                  },
                  onSaved: (value) => itemCost = value!.replaceAll(',', ''),
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter item cost';
                    final numericString = value.replaceAll(',', '');
                    if (double.tryParse(numericString) == null)
                      return 'Please enter a valid number';
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  decoration: InputDecoration(labelText: 'Currency'),
                  onChanged: (newValue) {
                    setState(() {
                      selectedCurrency = newValue!;
                    });
                  },
                  items: currencies
                      .map((currency) => DropdownMenuItem<String>(
                            value: currency,
                            child: Text(currency),
                          ))
                      .toList(),
                ),
                DropdownButtonFormField<String>(
                  value: selectedPaymentMethod,
                  decoration: InputDecoration(labelText: 'Payment Method'),
                  onChanged: (newValue) {
                    setState(() {
                      selectedPaymentMethod = newValue!;
                    });
                  },
                  items: paymentMethods
                      .map((method) => DropdownMenuItem<String>(
                            value: method,
                            child: Text(method),
                          ))
                      .toList(),
                ),
                _buildTextField(
                  label: 'Description',
                  icon: Icons.description,
                  maxLines: 3,
                  onSaved: (value) => description = value!,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickImages,
                  child: Text('Upload Item Photos'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      _isLoading ? null : _submitForm, // Disable when loading
                  child: _isLoading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text('Submit'),
                ),
                if (_images.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Text('Uploaded Images:', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 10),
                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Image.file(
                            _images[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required void Function(String?) onSaved,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2.0),
          ),
        ),
        validator: validator,
        onSaved: onSaved,
        onChanged: onChanged,
      ),
    );
  }
}
