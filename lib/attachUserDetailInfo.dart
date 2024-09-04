import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class UserDetailForm extends StatefulWidget {
  @override
  _UserDetailFormState createState() => _UserDetailFormState();
}

class _UserDetailFormState extends State<UserDetailForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController(); // Controller for address
  String _email = '';
  String _selectedGender = 'Male';
  String _role = 'User'; // Default role
  File? _profilePicture;
  bool _isUserExist = false;
  bool _isLoading = true; // Add a loading state variable
  Position? _currentPosition; // To hold the current position

  @override
  void initState() {
    super.initState();
    _checkUserDetails();
    _getCurrentLocation(); // Get current location when initializing
  }

  Future<void> _checkUserDetails() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _email = user.email ?? '';
      final databaseRef = FirebaseDatabase.instance.ref().child('userDetails');
      final snapshot =
          await databaseRef.orderByChild('email').equalTo(_email).once();

      if (snapshot.snapshot.children.isNotEmpty) {
        setState(() {
          _isUserExist = true;
          final userData =
              snapshot.snapshot.children.first.value as Map<dynamic, dynamic>;
          _fullNameController.text = userData['fullName'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _addressController.text = userData['address'] ?? ''; // Load address
          _selectedGender = userData['gender'] ?? 'Male';
          _role = userData['role'] ?? 'User';
          // If you need to load the profile picture, you'll need additional logic to handle it
        });
      }
    }
    setState(() {
      _isLoading = false; // Stop loading when done
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled, request user to enable it
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permission denied.')),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    }
  }

  Future<void> _pickProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profilePicture = File(image.path);
      });
    }
  }

  Future<String> _uploadProfilePicture(File image) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_pictures/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = storageRef.putFile(image);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<bool> _isPhoneUnique(String phone) async {
    final databaseRef = FirebaseDatabase.instance.ref().child('userDetails');
    final snapshot =
        await databaseRef.orderByChild('phone').equalTo(phone).once();
    return snapshot.snapshot.children.isEmpty;


  }

  void _saveUserDetails() async {
    if (_formKey.currentState?.validate() ?? false) {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      final phoneUnique = await _isPhoneUnique(_phoneController.text);
      if (!phoneUnique) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phone number already exists')),
        );
        return;
      }

      final databaseRef =
          FirebaseDatabase.instance.ref().child('userDetails').child(user.uid);

      String profilePictureUrl = '';
      if (_profilePicture != null) {
        try {
          profilePictureUrl = await _uploadProfilePicture(_profilePicture!);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload profile picture: $e')),
          );
          return;
        }
      }

      final Map<String, dynamic> userData = {
        'fullName': _fullNameController.text,
        'phone': _phoneController.text,
        'email': _email,
        'gender': _selectedGender,
        'role': _role,
        'profilePictureUrl': profilePictureUrl,
        'address': _addressController.text, // Save address
        'latitude': _currentPosition?.latitude ?? '', // Save latitude
        'longitude': _currentPosition?.longitude ?? '', // Save longitude
      };

      try {
        await databaseRef.set(userData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isUserExist
                  ? 'Profile updated successfully'
                  : 'Profile created successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show a loading spinner while fetching user details
      return Scaffold(
        appBar: AppBar(
          title: Text('Your detail info'),
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Your detail info'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture
                Center(
                  child: GestureDetector(
                    onTap: _pickProfilePicture,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profilePicture != null
                          ? FileImage(_profilePicture!)
                          : null,
                      child: _profilePicture == null
                          ? Icon(Icons.camera_alt,
                              size: 50, color: Colors.grey[800])
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(labelText: 'Full Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Address'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Gender
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('Gender:'),
                    Radio<String>(
                      value: 'Male',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value ?? 'Male';
                        });
                      },
                    ),
                    Text('Male'),
                    Radio<String>(
                      value: 'Female',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value ?? 'Female';
                        });
                      },
                    ),
                    Text('Female'),
                    Radio<String>(
                      value: 'Other',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value ?? 'Other';
                        });
                      },
                    ),
                    Text('Other'),
                  ],
                ),
                SizedBox(height: 16),
                // Role
                TextFormField(
                  initialValue: _role,
                  decoration: InputDecoration(labelText: 'Role'),
                  onChanged: (value) {
                    _role = value;
                  },
                ),
                SizedBox(height: 16),
                // Save/Update Button
                Center(
                  child: ElevatedButton(
                    onPressed: _saveUserDetails,
                    child:
                        Text(_isUserExist ? 'Update Details' : 'Save Details'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
