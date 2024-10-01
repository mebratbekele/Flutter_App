import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_application_1/Employee/employeeRequest.dart';
import 'package:flutter_application_1/Employer/employerRequest.dart';
import 'package:flutter_application_1/buyer/post.dart';
import 'package:flutter_application_1/seller/post.dart';
import 'package:geolocator/geolocator.dart';

class UserInfoPage extends StatefulWidget {
  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('userDetails');
  final DatabaseReference _requestsRef =
      FirebaseDatabase.instance.ref().child('requests');

  bool _loading = true;
  int _loadingPercentage = 0;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _selectedCategory = '';
  String? _selectedUserEmail;

  List<Map<String, dynamic>> _userDataList = [];
  List<Map<String, dynamic>> _filteredUserDataList = [];

  final _formKey = GlobalKey<FormState>(); // Key for the form

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _searchController.addListener(_filterUserData);
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _loading = true;
      _loadingPercentage = 0;
    });

    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 500));
      _updateLoadingPercentage(25);

      // Fetch data
      DatabaseEvent event = await _dbRef.once();
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final userDataList = <Map<String, dynamic>>[];

        data.forEach((key, value) {
          final userData = value as Map<dynamic, dynamic>;
          userDataList.add({
            'profilePictureUrl': userData['profilePictureUrl'] ?? '',
            'fullName': userData['fullName'] ?? '',
            'email': userData['email'] ?? '',
            'phone': userData['phone'] ?? '',
            'address': userData['address'] ?? '',
            'latitude': userData['latitude']?.toDouble() ?? 0.0,
            'longitude': userData['longitude']?.toDouble() ?? 0.0,
          });
        });

        setState(() {
          _userDataList = userDataList;
          _filteredUserDataList = userDataList; // Initialize with all data
        });

        _updateLoadingPercentage(50);
        await _calculateDistance();
      } else {
        print('No data available');
      }
      _updateLoadingPercentage(100);
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _calculateDistance() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _filteredUserDataList.forEach((user) {
          double distance = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                user['latitude'],
                user['longitude'],
              ) /
              1000; // Convert to kilometers

          user['distance'] = distance.toStringAsFixed(2) + ' km';
        });
        _filteredUserDataList.sort((a, b) =>
            (a['distance'] as String).compareTo(b['distance'] as String));
      });
    } catch (e) {
      print('Error calculating distance: $e');
    }
  }

  void _filterUserData() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredUserDataList = _userDataList.where((user) {
        final address = user['address']?.toLowerCase() ?? '';
        return address.contains(query);
      }).toList();
    });
  }

  void _updateLoadingPercentage(int percentage) {
    setState(() {
      _loadingPercentage = percentage;
    });
  }

  void _onContactButtonPressed(String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contact Us'),
          content: _buildContactForm(),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel, color: Colors.red), // Prefix icon
                  SizedBox(width: 8), // Space between icon and text
                  Text('Cancel'),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                _onNexttForm(email);
                // Navigator.of(context).pop(); // Close the dialog
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.navigate_next, color: Colors.blue), // Prefix icon
                  SizedBox(width: 8), // Space between icon and text
                  Text('Next'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactForm() {
    return Form(
      key: _formKey, // Attach the form key
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Your Position',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          _buildDropdownField(
            'Category',
            ['Job Seeker', 'Employer', 'Seller', 'Buyer'],
            _selectedCategory,
            (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onNexttForm(String email) async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCategory == "Employer") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobFormRequest(email: email),
          ),
        );
      } else if (_selectedCategory == "Seller") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SellerForm(email: email),
          ),
        );
      } else if (_selectedCategory == "Job Seeker") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobSeekerRequestScreen(email: email),
          ),
        );
      } else if (_selectedCategory == "Buyer") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BuyerForm(email: email),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select Your Position')),
      );
    }
  }

  Future<void> _onSubmitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final category = _selectedCategory;
      final description = _descriptionController.text;
      final fullName = _fullNameController.text;
      final email = _emailController.text;
      final phone = _phoneController.text;
      final address = _addressController.text;
      final selectedUserEmail = _selectedUserEmail;

      if (selectedUserEmail == null || selectedUserEmail.isEmpty) {
        print('No user selected.');
        return;
      }

      // Save the form data to the "requests" table in Firebase
      try {
        await _requestsRef.push().set({
          'category': category,
          'description': description,
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'address': address,
          'selectedUserEmail': selectedUserEmail,
          'timestamp':
              ServerValue.timestamp, // Add a timestamp for sorting or filtering
        });

        print('Form submitted successfully!');
        // Optionally show a success message
      } catch (e) {
        print('Error submitting form: $e');
        // Optionally show an error message
      }
    } else {
      print('Form validation failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Brokers Information ...'),
        backgroundColor: Colors.cyan,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false);
          },
        ),
      ),
      body: Stack(
        children: [
          _loading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text('Loading $_loadingPercentage%',
                          style: TextStyle(fontSize: 18)),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      // Search Section
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: _buildTextField(
                          _searchController,
                          'Search by Address',
                          'Search...',
                        ),
                      ),

                      // Profile Section
                      if (_filteredUserDataList.isNotEmpty)
                        ..._filteredUserDataList.map((userData) {
                          return Card(
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: userData['profilePictureUrl'] != ''
                                  ? Image.network(userData['profilePictureUrl'])
                                  : Icon(Icons.person),
                              title: Text(userData['fullName']),
                              subtitle: Text(
                                  '${userData['email']}\n${userData['address']}\n${userData['distance'] ?? ''}'),
                              onTap: () {
                                _onContactButtonPressed(userData['email']);
                              },
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
          // Align(
          //   alignment: Alignment.bottomRight,
          //   child: Padding(
          //     padding: const EdgeInsets.all(16.0),
          //     child: ElevatedButton(
          //       onPressed: () =>
          //           _onContactButtonPressed(''), // Pass the email if needed
          //       style: ElevatedButton.styleFrom(
          //         foregroundColor: Colors.white,
          //         backgroundColor: Colors.blue, // Button text color
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(12), // Rounded corners
          //         ),
          //         padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          //       ),
          //       child: Row(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           Icon(Icons.contact_mail, color: Colors.white),
          //           SizedBox(width: 8),
          //           Text('Contact Us',
          //               style: TextStyle(
          //                   fontSize: 16, fontWeight: FontWeight.bold)),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    // Create a unique set of dropdown items
    final uniqueItems = items.toSet().toList();

    return DropdownButtonFormField<String>(
      value: uniqueItems.contains(selectedValue) ? selectedValue : null,
      items: uniqueItems.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select Your $label';
        }
        return null;
      },
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint,
      {bool isEmail = false, bool isPhone = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(),
      ),
      keyboardType: isPhone
          ? TextInputType.phone
          : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        if (isPhone && !RegExp(r'^\d+$').hasMatch(value)) {
          return 'Please enter a valid phone number';
        }
        return null;
      },
    );
  }
}
