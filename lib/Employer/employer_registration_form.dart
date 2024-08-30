import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class EmployerRegistrationForm extends StatefulWidget {
  final Map<String, dynamic> employee;
  final String employeeId;

  EmployerRegistrationForm({required this.employee, required this.employeeId});

  @override
  _EmployerRegistrationFormState createState() =>
      _EmployerRegistrationFormState();
}

class _EmployerRegistrationFormState extends State<EmployerRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _employerFullNameController;
  late TextEditingController _employerEmailController;
  late TextEditingController _employerPhoneController;
  late TextEditingController _employerEmergencyFullNameController;
  late TextEditingController _employerEmergencyPhoneController;
  late TextEditingController _employerEmergencyAddressController;
  late TextEditingController _employerEmergencyEmailController;
  late TextEditingController _employerAddressController;
  String? _employerGender;
  String? _profilePictureUrl;
  String? _idCardFrontUrl;
  String? _idCardBackUrl;
  Uint8List? _employerSignatureData;
  String? _employerSignatureUrl;
  Uint8List? _emergencySignatureData;
  String? _emergencySignatureUrl;
  Uint8List? _employeeSignatureData;
  String? _employeeSignatureUrl;
  final DatabaseReference _employerRef =
      FirebaseDatabase.instance.reference().child('employerTable');
  final SignatureController _employerSignatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );
  final SignatureController _emergencySignatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );
  final SignatureController _employeeSignatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void initState() {
    super.initState();
    _employerFullNameController =
        TextEditingController(text: widget.employee['employerFullName']);
    _employerEmailController =
        TextEditingController(text: widget.employee['employerEmail']);
    _employerPhoneController =
        TextEditingController(text: widget.employee['employerPhone']);
    _employerEmergencyFullNameController = TextEditingController(
        text: widget.employee['employerEmergencyFullName']);
    _employerEmergencyPhoneController =
        TextEditingController(text: widget.employee['employerEmergencyPhone']);
    _employerEmergencyAddressController = TextEditingController(
        text: widget.employee['employerEmergencyAddress']);
    _employerEmergencyEmailController =
        TextEditingController(text: widget.employee['employerEmergencyEmail']);
    _employerAddressController =
        TextEditingController(text: widget.employee['employerAddress']);
    _employerGender = widget.employee['employerGender'];
    _profilePictureUrl = widget.employee['employerProfilePicture'];
    _idCardFrontUrl = widget.employee['employerIdCardFront'];
    _idCardBackUrl = widget.employee['employerIdCardBack'];
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      Reference reference =
          FirebaseStorage.instance.ref().child('uploads/$path/$fileName');
      UploadTask uploadTask = reference.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload file: $e')),
      );
      return null;
    }
  }

  Future<void> _pickImage(String fieldName) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.camera); // or ImageSource.gallery

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String? downloadUrl = await _uploadFile(file, fieldName);
      setState(() {
        if (fieldName == 'profilePicture') {
          _profilePictureUrl = downloadUrl;
        } else if (fieldName == 'idCardFront') {
          _idCardFrontUrl = downloadUrl;
        } else if (fieldName == 'idCardBack') {
          _idCardBackUrl = downloadUrl;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected')),
      );
    }
  }

  Future<void> _saveSignature(SignatureController controller,
      ValueChanged<Uint8List?> onSuccess) async {
    if (controller.isEmpty) return;

    try {
      final Uint8List? data = await controller.toPngBytes();
      if (data != null) {
        setState(() {
          onSuccess(data);
        });
        await _uploadSignature(
            data,
            controller == _employerSignatureController
                ? 'employerSignature'
                : controller == _emergencySignatureController
                    ? 'emergencySignature'
                    : 'employeeSignature');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save signature: $e')),
      );
    }
  }

  Future<void> _uploadSignature(Uint8List data, String path) async {
    try {
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_signature.png';
      Reference reference =
          FirebaseStorage.instance.ref().child('signatures/$path/$fileName');
      UploadTask uploadTask = reference.putData(data);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        if (path == 'employerSignature') {
          _employerSignatureUrl = downloadUrl;
        } else if (path == 'emergencySignature') {
          _emergencySignatureUrl = downloadUrl;
        } else if (path == 'employeeSignature') {
          _employeeSignatureUrl = downloadUrl;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload signature: $e')),
      );
    }
  }

  Future<void> _saveEmployeeData() async {
    // Check if the form is valid
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Posted Job Deactivation'),
          content: Text('Are you sure you want to Deactivate the posted job?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Save signatures
        await _saveSignature(_employerSignatureController,
            (data) => _employerSignatureData = data);
        await _saveSignature(_emergencySignatureController,
            (data) => _emergencySignatureData = data);
        await _saveSignature(_employeeSignatureController,
            (data) => _employeeSignatureData = data);

        // Prepare data to save
        final employerData = {
          'employeeId': widget.employeeId,
          'employerFullName': _employerFullNameController.text,
          'employerEmail': _employerEmailController.text,
          'employerPhone': _employerPhoneController.text,
          'employerGender': _employerGender,
          'employerEmergencyFullName':
              _employerEmergencyFullNameController.text,
          'employerEmergencyPhone': _employerEmergencyPhoneController.text,
          'employerEmergencyAddress': _employerEmergencyAddressController.text,
          'employerEmergencyEmail': _employerEmergencyEmailController.text,
          'employerAddress': _employerAddressController.text,
          'employerProfilePicture': _profilePictureUrl,
          'employerIdCardFront': _idCardFrontUrl,
          'employerIdCardBack': _idCardBackUrl,
          'employerSignature': _employerSignatureUrl,
          'emergencySignature': _emergencySignatureUrl,
          'employeeSignature': _employeeSignatureUrl,
        };

        // Save data to the database
        final databaseReference =
            FirebaseDatabase.instance.ref().child('employerTable');
        await databaseReference.push().set(employerData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Employee Acceptance successfully')),
        );

        // Update job status
        await _updateJobStatus(widget.employeeId);

        // Navigate to a different screen
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close the current screen
        }
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept employee: $error')),
        );
      }
    } else {
      // If not confirmed, show a cancellation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Posted job active until now')),
      );

      // Ensure Navigator operations are appropriate
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close the current screen if possible
      }
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  Future<void> _updateJobStatus(String employeeId) async {
    final employesRef = FirebaseDatabase.instance.ref('employeeTable');
    await employesRef.child(employeeId).update({'status': 1});
    final jobId = await _getJobIdByEmployeeId(employeeId);

    if (jobId != null) {
      try {
        final jobsRef = FirebaseDatabase.instance.ref('jobs');
        await jobsRef.child(jobId).update({'status': 1});
      } catch (error) {
        print('Failed to update job status: $error');
        throw error; // Re-throw the error to handle it in the parent method
      }
    }
  }

  Future<String?> _getJobIdByEmployeeId(String employeeId) async {
    // Replace with the actual logic to get jobId based on employeeId
    // This is a placeholder implementation
    final employeeRef = FirebaseDatabase.instance.ref('employeeTable');
    final snapshot = await employeeRef.child(employeeId).once();
    final employeeData = snapshot.snapshot.value as Map?;
    return employeeData?['jobId'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accept Pending Employee'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/viewEmployeeList', (route) => false);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display Employee ID
                      Text(
                        'Employee ID: ${widget.employeeId}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Employer Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Upload Profile Picture Button
                      ElevatedButton(
                        onPressed: () => _pickImage('profilePicture'),
                        child: Text('Upload Employer Profile Picture'),
                      ),
                      SizedBox(height: 16),

                      // Employer Informatio
                      // Employer Full Name
                      TextFormField(
                        controller: _employerFullNameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter full name' : null,
                      ),

                      // Employer Email
                      TextFormField(
                        controller: _employerEmailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter email' : null,
                      ),

                      // Employer Phone
                      TextFormField(
                        controller: _employerPhoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter phone number' : null,
                      ),
                      SizedBox(height: 16),

                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        value: _employerGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: ['Male', 'Female'].map((gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _employerGender = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select gender' : null,
                      ),
                      SizedBox(height: 16),

                      // Emergency Contact
                      Text(
                        'Emergency Contact',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Emergency Contact Name
                      TextFormField(
                        controller: _employerEmergencyFullNameController,
                        decoration: InputDecoration(
                          labelText: 'Emergency Contact Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Please enter emergency contact name'
                            : null,
                      ),

                      // Emergency Contact Phone
                      TextFormField(
                        controller: _employerEmergencyPhoneController,
                        decoration: InputDecoration(
                          labelText: 'Emergency Contact Phone',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Please enter emergency contact phone'
                            : null,
                      ),

                      // Emergency Contact Address
                      TextFormField(
                        controller: _employerEmergencyAddressController,
                        decoration: InputDecoration(
                          labelText: 'Emergency Contact Address',
                          prefixIcon: Icon(Icons.home),
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Please enter emergency contact address'
                            : null,
                      ),

                      // Emergency Contact Email
                      TextFormField(
                        controller: _employerEmergencyEmailController,
                        decoration: InputDecoration(
                          labelText: 'Emergency Contact Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Please enter emergency contact email'
                            : null,
                      ),
                      SizedBox(height: 16),

                      // Address
                      Text(
                        'Address',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Address
                      TextFormField(
                        controller: _employerAddressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.home),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter address' : null,
                      ),
                      SizedBox(height: 16),

                      // Documents
                      Text('Documents'),
                      SizedBox(height: 16),

                      // ID Card Upload Buttons
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _pickImage('idCardFront'),
                            child: Text('Upload ID Card Front'),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _pickImage('idCardBack'),
                            child: Text('Upload ID Card Back'),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Signatures
                      Text('Signatures'),
                      SizedBox(height: 16),

                      // Employer Signature
                      Text('Employer Signature'),
                      Signature(
                        controller: _employerSignatureController,
                        height: 150,
                        backgroundColor: Colors.grey[200]!,
                      ),
                      ElevatedButton(
                        onPressed: () => _saveSignature(
                            _employerSignatureController,
                            (data) => _employerSignatureData = data),
                        child: Text('Save Employer Signature'),
                      ),
                      SizedBox(height: 16),

                      // Emergency Signature
                      Text('Emergency Signature'),
                      Signature(
                        controller: _emergencySignatureController,
                        height: 150,
                        backgroundColor: Colors.grey[200]!,
                      ),
                      ElevatedButton(
                        onPressed: () => _saveSignature(
                            _emergencySignatureController,
                            (data) => _emergencySignatureData = data),
                        child: Text('Save Emergency Signature'),
                      ),
                      SizedBox(height: 16),

                      // Employee Signature
                      Text('Employee Signature'),
                      Signature(
                        controller: _employeeSignatureController,
                        height: 150,
                        backgroundColor: Colors.grey[200]!,
                      ),
                      ElevatedButton(
                        onPressed: () => _saveSignature(
                            _employeeSignatureController,
                            (data) => _employeeSignatureData = data),
                        child: Text('Save Employee Signature'),
                      ),
                      SizedBox(height: 16),

                      // Save Button
                      Center(
                        child: ElevatedButton(
                          onPressed: _saveEmployeeData,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue, // Text and icon color
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0), // Padding around the button
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8.0), // Optional: round the corners
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.save,
                                  size: 24.0), // Replace with your desired icon
                              SizedBox(
                                  width:
                                      8.0), // Spacing between the icon and text
                              Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 20, // Increase text size here
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
