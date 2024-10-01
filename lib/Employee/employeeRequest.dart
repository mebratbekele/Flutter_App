import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class JobSeekerRequestScreen extends StatefulWidget {
  final String email;

  JobSeekerRequestScreen({required this.email});

  @override
  _EmployeeRegistrationScreenState createState() =>
      _EmployeeRegistrationScreenState();
}

class _EmployeeRegistrationScreenState extends State<JobSeekerRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Track loading state
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

  Future<bool> _isUniqueEmail(String email) async {
    final databaseReference =
        FirebaseDatabase.instance.reference().child('employeeTable');
    final snapshot =
        await databaseReference.orderByChild('email').equalTo(email).once();
    return snapshot.snapshot.value == null;
  }

  Future<bool> _isUniquePhone(String phone) async {
    final databaseReference =
        FirebaseDatabase.instance.reference().child('employeeTable');
    final snapshot =
        await databaseReference.orderByChild('phone').equalTo(phone).once();
    return snapshot.snapshot.value == null;
  }

  Future<void> _saveEmployeeData() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_frontIdCard == null || _backIdCard == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Front and back ID cards are required')),
        );
        return;
      }

      setState(() {
        _isLoading = true; // Start loading
      });

      final email = _emailController.text;
      final phone = _phoneController.text;

      // Check for unique email and phone
      final isEmailUnique = await _isUniqueEmail(email);
      final isPhoneUnique = await _isUniquePhone(phone);

      if (!isEmailUnique) {
        setState(() {
          _isLoading = false; // Stop loading
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email is already registered')),
        );
        return;
      }

      if (!isPhoneUnique) {
        setState(() {
          _isLoading = false; // Stop loading
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phone number is already registered')),
        );
        return;
      }

      // Upload files if they exist
      String? profilePictureUrl;
      if (_profilePicture != null) {
        profilePictureUrl = await _uploadFile(
          File(_profilePicture!.path),
          'profile_pictures',
        );
      }

      String? frontIdCardUrl;
      if (_frontIdCard != null) {
        frontIdCardUrl = await _uploadFile(
          File(_frontIdCard!.path),
          'id_cards/front',
        );
      }

      String? backIdCardUrl;
      if (_backIdCard != null) {
        backIdCardUrl = await _uploadFile(
          File(_backIdCard!.path),
          'id_cards/back',
        );
      }

      String? documentUrl;
      if (_documentPath != null) {
        documentUrl = await _uploadFile(
          File(_documentPath!),
          'documents',
        );
      }

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
        'status': 'request',
        'contactEmail': widget.email,
      };

      final databaseReference =
          FirebaseDatabase.instance.reference().child('employeeTable');
      databaseReference.push().set(employeeData).then((_) {
        setState(() {
          _isLoading = false; // Stop loading
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Successful')),
        );
        Navigator.pushNamedAndRemoveUntil(
            context, '/listOfJobs', (route) => false);
      }).catchError((error) {
        setState(() {
          _isLoading = false; // Stop loading
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job Seeker'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registration Form',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  // Contact Email
                  _buildInfoSection('Contact Email:', widget.email),
                  SizedBox(height: 20),

                  // Job ID
                  //  _buildInfoSection('Job ID:', widget.jobId),
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
                    label: 'Require job,salary...',
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.send, color: Colors.green),
                      ),
                    ),
                    label: Text('', style: TextStyle(fontSize: 24)),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      textStyle: TextStyle(fontSize: 24),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(), // Show loading indicator
            ),
        ],
      ),
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
      items: ['Male', 'Female', 'Other'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _gender = newValue!;
        });
      },
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: Icon(Icons.transgender),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildImageUploadSection(String label, XFile? image, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: image != null
                  ? Image.file(
                      File(image.path),
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 100,
                      color: Colors.grey[200],
                      child: Center(child: Text('No $type Selected')),
                    ),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: () => _pickImage(type),
              child: Text('Select $type'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Document:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        _documentPath != null
            ? Text('Document: ${_documentPath!.split('/').last}')
            : Container(
                color: Colors.grey[200],
                height: 50,
                child: Center(child: Text('No Document Selected')),
              ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _pickDocument,
          child: Text('Select Document'),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
