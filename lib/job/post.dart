import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity package
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import services for input formatting
import 'package:flutter_application_1/job/custom/number_comma_separater.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:flutter_application_1/job/Model/job.dart'; // Import your Job model
import 'package:intl/intl.dart'; // Import intl package for DateFormat

// Ensure you have your CurrencyInputFormatter class available here

class JobForm extends StatefulWidget {
  @override
  _JobFormState createState() => _JobFormState();
}

class _JobFormState extends State<JobForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _salaryController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requiredNumberController = TextEditingController();
  final _postDateController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  late String userEmail;
  Position? _currentPosition;

  final List<String> _currencies = ['ETB', 'USD', 'EUR', 'GBP', 'INR'];
  String _selectedCurrency = 'ETB';

  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _getUserId();
    _getCurrentLocation();
  }

  Future<void> _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email!;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in.')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are not enabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          print('Location permissions are not granted.');
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
      print('Error getting current location: $e');
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (selectedDate != null) {
      controller.text = "${selectedDate.toLocal().toString().split(' ')[0]}";
    }
  }

  Future<void> _submitJob() async {
    // Check for connectivity
    final ConnectivityResult connectivityResult =
        await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('No internet connection. Please connect to the network.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final jobId = FirebaseDatabase.instance.ref().child('jobs').push().key;

      final job = Job(
        jobId: jobId!,
        userEmail: userEmail,
        name: _nameController.text,
        salary: double.parse(_salaryController.text.replaceAll(',', '')),
        currency: _selectedCurrency,
        location: _locationController.text,
        description: _descriptionController.text,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        gender: _selectedGender,
        numberRequired: int.parse(_requiredNumberController.text),
        status: 0, // Default value
        postDate: _postDateController.text.isNotEmpty
            ? DateTime.parse(_postDateController.text)
            : null,
        startDate: _startDateController.text.isNotEmpty
            ? DateTime.parse(_startDateController.text)
            : null,
        endDate: _endDateController.text.isNotEmpty
            ? DateTime.parse(_endDateController.text)
            : null,
      );

      try {
        await FirebaseDatabase.instance
            .ref()
            .child('jobs')
            .child(jobId)
            .set(job.toMap());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job posted successfully!')),
        );
        Navigator.pushNamedAndRemoveUntil(
            context, '/listOfJobsBasedOnUser', (route) => false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting job')),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    String? hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    required FormFieldValidator<String>? validator,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          hintText: hintText,
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines ?? 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post a Job'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/listOfJobsBasedOnUser', (route) => false);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Job Name',
                prefixIcon: Icons.work,
                hintText: 'Enter the job title',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the job name';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _salaryController,
                label: 'Salary',
                prefixIcon: Icons.attach_money,
                hintText: 'Enter the salary amount',
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the salary';
                  }
                  final numericRegExp = RegExp(r'^\d+(,\d{3})*$');
                  if (!numericRegExp.hasMatch(value.replaceAll(',', ''))) {
                    return 'Please enter a valid numeric value';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                ),
                items: _currencies.map((currency) {
                  return DropdownMenuItem<String>(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a currency';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _locationController,
                label: 'Location',
                prefixIcon: Icons.location_on,
                hintText: 'Enter the job location',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the location';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                prefixIcon: Icons.description,
                hintText: 'Enter job description',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the description';
                  }
                  return null;
                },
              ),
              Text('Required Gender',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Male'),
                      value: 'Male',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Female'),
                      value: 'Female',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Both'),
                      value: 'Both',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              _buildTextField(
                controller: _requiredNumberController,
                label: 'Number Required',
                prefixIcon: Icons.format_list_numbered,
                hintText: 'Enter the number of positions required',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              // Post Date
              GestureDetector(
                onTap: () => _selectDate(_postDateController),
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: _postDateController,
                    label: 'Post Date (YYYY-MM-DD)',
                    prefixIcon: Icons.date_range,
                    hintText: 'Select the post date',
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          DateTime.parse(value);
                        } catch (_) {
                          return 'Enter a valid date (YYYY-MM-DD)';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ),
              // Start Date
              GestureDetector(
                onTap: () => _selectDate(_startDateController),
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: _startDateController,
                    label: 'Start Date (YYYY-MM-DD)',
                    prefixIcon: Icons.date_range,
                    hintText: 'Select the start date',
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          DateTime.parse(value);
                        } catch (_) {
                          return 'Enter a valid date (YYYY-MM-DD)';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ),
              // End Date
              GestureDetector(
                onTap: () => _selectDate(_endDateController),
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: _endDateController,
                    label: 'End Date (YYYY-MM-DD)',
                    prefixIcon: Icons.date_range,
                    hintText: 'Select the end date',
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          DateTime.parse(value);
                        } catch (_) {
                          return 'Enter a valid date (YYYY-MM-DD)';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitJob,
                child: Text('Post Job'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
