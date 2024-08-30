import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EmployeeRegistrationScreen extends StatefulWidget {
  final String email;
  final String jobId;

  EmployeeRegistrationScreen({required this.email, required this.jobId});

  @override
  _EmployeeRegistrationScreenState createState() =>
      _EmployeeRegistrationScreenState();
}

class _EmployeeRegistrationScreenState
    extends State<EmployeeRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _resumeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _gender = 'Male'; // Default gender
  XFile? _profilePicture; // Variable to store profile picture
  XFile? _frontIdCard; // Variable to store front side of ID card
  XFile? _backIdCard; // Variable to store back side of ID card
  String? _documentPath; // Variable to store additional document path

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String label) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        switch (label) {
          case 'Profile Picture':
            _profilePicture = pickedFile;
            break;
          case 'Front ID Card':
            _frontIdCard = pickedFile;
            break;
          case 'Back ID Card':
            _backIdCard = pickedFile;
            break;
        }
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _documentPath = result.files.single.path;
      });
    }
  }

  Future<String?> _uploadFile(File file, String folderName) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('$folderName/${DateTime.now().toIso8601String()}');
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _saveEmployeeData() async {
    if (_profilePicture != null &&
        _frontIdCard != null &&
        _backIdCard != null &&
        _documentPath != null) {
      final profilePictureUrl = await _uploadFile(
        File(_profilePicture!.path),
        'profile_pictures',
      );
      final frontIdCardUrl = await _uploadFile(
        File(_frontIdCard!.path),
        'id_cards/front',
      );
      final backIdCardUrl = await _uploadFile(
        File(_backIdCard!.path),
        'id_cards/back',
      );
      final documentUrl = await _uploadFile(
        File(_documentPath!),
        'documents',
      );

      final employeeData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'gender': _gender,
        'email': _emailController.text,
        'resume': _resumeController.text,
        'profilePicture': profilePictureUrl,
        'frontIdCard': frontIdCardUrl,
        'backIdCard': backIdCardUrl,
        'documentPath': documentUrl,
        'jobId': widget.jobId,
        'contactEmail': widget.email,
      };

      final databaseReference =
          FirebaseDatabase.instance.reference().child('employeeTable');
      databaseReference.push().set(employeeData).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Successful')),
        );
        Navigator.pushNamedAndRemoveUntil(
            context, '/listOfJobs', (route) => false);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register: $error')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Please upload profile picture, front ID card, back ID card, and additional document')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Registration'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Employee Registration',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Contact Email
              _buildInfoSection('Contact Email:', widget.email),
              SizedBox(height: 20),

              // Job ID
              _buildInfoSection('Job ID:', widget.jobId),
              SizedBox(height: 20),

              // Profile Picture Upload
              _buildImageUploadSection(
                'Profile Picture:',
                _profilePicture,
                'Profile Picture',
              ),
              SizedBox(height: 20),

              // Front ID Card Upload
              _buildImageUploadSection(
                'Front ID Card:',
                _frontIdCard,
                'Front ID Card',
              ),
              SizedBox(height: 20),

              // Back ID Card Upload
              _buildImageUploadSection(
                'Back ID Card:',
                _backIdCard,
                'Back ID Card',
              ),
              SizedBox(height: 20),

              // Additional Document Upload
              _buildDocumentUploadSection(),
              SizedBox(height: 20),

              // Name Field
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
              ),
              SizedBox(height: 16),

              // Phone Number Field
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),

              // Address Field
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.home,
              ),
              SizedBox(height: 16),

              // Gender Selection
              _buildDropdownField(),
              SizedBox(height: 16),

              // Email Field
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),

              // Resume Field
              _buildTextField(
                controller: _resumeController,
                label: 'Resume (Link or Description)',
                icon: Icons.description,
              ),
              SizedBox(height: 20),

              // Submit Button
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _saveEmployeeData();
                  }
                },
                icon: Container(
                  width: 40, // Adjust the size of the circle as needed
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white, // Background color of the circle
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(Icons.send, color: Colors.green), // Icon color
                  ),
                ),
                label: Text('',
                    style:
                        TextStyle(fontSize: 24)), // Adjust text size as needed
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  textStyle: TextStyle(fontSize: 24),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection(
      String label, XFile? image, String imageType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(imageType),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(image.path),
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(Icons.camera_alt, size: 50, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Document:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickDocument,
          icon: Icon(Icons.upload_file),
          label: Text(
              _documentPath != null ? 'Document Selected' : 'Upload Document'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _gender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: Icon(Icons.transgender),
        border: OutlineInputBorder(),
      ),
      items: ['Male', 'Female', 'Both']
          .map((gender) => DropdownMenuItem<String>(
                value: gender,
                child: Text(gender),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _gender = value;
          });
        }
      },
      validator: (value) {
        if (value == null) {
          return 'Please select your gender';
        }
        return null;
      },
    );
  }
}
