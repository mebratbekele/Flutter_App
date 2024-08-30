import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EmployeeForm extends StatefulWidget {
  final String? employeeId;

  EmployeeForm({this.employeeId});

  @override
  _EmployeeFormState createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  XFile? _image;
  String? _selectedGender;
  late DatabaseReference _employeeRef;

  @override
  void initState() {
    super.initState();
    if (widget.employeeId != null) {
      _employeeRef = FirebaseDatabase.instance
          .ref()
          .child('employees')
          .child(widget.employeeId!);
      _loadEmployeeData();
    } else {
      _employeeRef = FirebaseDatabase.instance.ref().child('employees').push();
    }
  }

  Future<void> _loadEmployeeData() async {
    DataSnapshot snapshot = await _employeeRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      _nameController.text = data['full_name'];
      _ageController.text = data['age'].toString();
      _phoneController.text = data['phone'];
      _selectedGender = data['gender'];
      // Load the image if available
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedFile;
    });
  }

  Future<void> _saveData() async {
    if (_formKey.currentState?.validate() == true && _selectedGender != null) {
      try {
        String? downloadUrl;
        if (_image != null) {
          String fileName = DateTime.now().toString();
          Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('employee_photos')
              .child(fileName);
          UploadTask uploadTask = storageRef.putFile(File(_image!.path));
          TaskSnapshot snapshot = await uploadTask;
          downloadUrl = await snapshot.ref.getDownloadURL();
        }

        await _employeeRef.set({
          'full_name': _nameController.text,
          'gender': _selectedGender!,
          'age': int.parse(_ageController.text),
          'phone': _phoneController.text,
          'photo_url': downloadUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Employee saved successfully!')));
        Navigator.pop(context);
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving employee')));
      }
    } else if (_selectedGender == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select a gender')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // You can choose a different color
        title:
            Text(widget.employeeId == null ? 'Add Employee' : 'Edit Employee'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/viewEmployee', (route) => false);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              Text('Gender'),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text('Male'),
                      leading: Radio<String>(
                        value: 'Male',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text('Female'),
                      leading: Radio<String>(
                        value: 'Female',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter age';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _image == null
                  ? Text('No image selected.')
                  : Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxHeight: 200,
                      ),
                      child: Image.file(
                        File(_image!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Select Image'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveData,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
