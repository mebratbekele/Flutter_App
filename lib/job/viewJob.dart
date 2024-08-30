import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Employee/employee_registration_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class JobList extends StatefulWidget {
  @override
  _JobListState createState() => _JobListState();
}

class _JobListState extends State<JobList> {
  final DatabaseReference _jobsRef =
      FirebaseDatabase.instance.ref().child('jobs');
  bool _isLoading = true;
  List<Map<dynamic, dynamic>> _jobs = [];
  List<Map<dynamic, dynamic>> _filteredJobs = [];
  final TextEditingController _searchController = TextEditingController();
  Position? _currentPosition;
  String _currentLocationName = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _searchController.addListener(_filterJobs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });

      // Reverse geocoding to get the location name
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _currentLocationName =
              '${placemark.locality}, ${placemark.administrativeArea}';
        });
      }
      _fetchJobs(); // Fetch jobs after getting location
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<void> _fetchJobs() async {
    try {
      final snapshot = await _jobsRef.once();
      if (snapshot.snapshot.exists) {
        final jobs = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);

        // Filter jobs where status == 0
        final filteredJobs = jobs.values
            .where((job) => (job['status'] as int?) == 0)
            .toList()
            .cast<Map<dynamic, dynamic>>();

        setState(() {
          _jobs = filteredJobs;
          _filteredJobs = _jobs; // Initially, show all jobs
          if (_currentPosition != null) {
            _sortJobsByDistance();
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching jobs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterJobs() {
    final query = _searchController.text.toLowerCase();
    final filteredJobs = _jobs.where((job) {
      final location = (job['location'] as String?)?.toLowerCase() ?? '';
      return location.contains(query);
    }).toList();

    setState(() {
      _filteredJobs = filteredJobs;
      if (_currentPosition != null) {
        _sortJobsByDistance();
      }
    });
  }

  void _sortJobsByDistance() {
    _filteredJobs.sort((a, b) {
      final distanceA = _calculateDistance(a['latitude'], a['longitude']);
      final distanceB = _calculateDistance(b['latitude'], b['longitude']);
      return distanceA.compareTo(distanceB);
    });
  }

  double _calculateDistance(double? lat, double? lon) {
    if (lat == null || lon == null || _currentPosition == null) {
      print('Invalid latitude, longitude, or current position');
      return double.infinity;
    }
    final distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lon,
        ) /
        1000; // Convert meters to kilometers
    return distance;
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Job Inquiry'},
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch ${emailUri.toString()}';
      }
    } catch (e) {
      print('Error launching email client: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch email client.')),
      );
    }
  }

  String? _formatDate(String? date) {
    if (date == null) return null;
    try {
      final parsedDate = DateTime.parse(date);
      final formatter = DateFormat('yyyy-MM-dd'); // Change to desired format
      return formatter.format(parsedDate);
    } catch (e) {
      print('Error formatting date: $e');
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPositionDisplay = _currentPosition != null
        ? 'Current Location: $_currentLocationName \nLatitude: ${_currentPosition!.latitude.toStringAsFixed(2)}, Longitude: ${_currentPosition!.longitude.toStringAsFixed(2)}'
        : 'Finding current location...';

    return Scaffold(
      appBar: AppBar(
        title: Text('Finding Jobs'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          },
        ),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.person_add),
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //             builder: (context) => EmployeeRegistrationScreen(
        //                   email: '',
        //                   jobId: '',
        //                 )),
        //       );
        //     },
        //   ),
        // ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Location',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              currentPositionDisplay,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _filteredJobs.isEmpty
                  ? Center(child: Text('No jobs available'))
                  : Expanded(
                      child: ListView.separated(
                        itemCount: _filteredJobs.length,
                        separatorBuilder: (context, index) => Divider(
                          color: const Color.fromARGB(255, 224, 224, 224),
                        ),
                        itemBuilder: (context, index) {
                          final job = _filteredJobs[index];
                          final distance = _calculateDistance(
                              job['latitude'], job['longitude']);
                          final formattedDistance = distance.toStringAsFixed(
                              2); // Format distance to 2 decimal places
                          final postDate = _formatDate(job['postDate']);
                          final startDate = _formatDate(job['startDate']);
                          final endDate = _formatDate(job['endDate']);
                          final salary = job['salary']?.toString() ??
                              '0'; // Convert to string if null
                          final currency = job['currency'] ?? 'No currency';

                          // Format the salary with commas
                          final salaryFormatted = NumberFormat('#,###').format(
                              int.tryParse(salary.replaceAll(
                                      RegExp(r'[^\d]'), '')) ??
                                  0);

                          return Card(
                            elevation: 4,
                            margin: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(
                                  Icons.question_mark,
                                  color: Colors.black,
                                ),
                              ),
                              title: Text(
                                job['name'] ?? 'No Job Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          color: Colors.blue),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Location: ${job['location'] ?? 'No Location'}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.attach_money,
                                          color: Colors.blue),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Salary: $salaryFormatted $currency',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.social_distance,
                                          color: Colors.blue),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Distance: ${formattedDistance} km',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.person, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Gender: ${job['gender'] ?? 'No gender'}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.numbers, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Required Number: ${job['numberRequired'] ?? 'No required'}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.description,
                                          color: Colors.blue),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Description: ${job['description'] ?? 'No Description'}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (postDate != null && postDate.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            color: Colors.blue),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Post Date: $postDate',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (startDate != null && startDate.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            color: Colors.blue),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Start Date: $startDate',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (endDate != null && endDate.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            color: Colors.blue),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'End Date: $endDate',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  final userEmail =
                                      job['userEmail'] as String? ??
                                          'No Contact';
                                  final jobId =
                                      job['jobId'] as String? ?? 'No Job ID';

                                  if (userEmail == 'No Contact') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'No contact email available')),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EmployeeRegistrationScreen(
                                        email: userEmail,
                                        jobId: jobId,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8), // Adjust padding if needed
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check,
                                        color: Colors.white), // Prefix icon
                                    SizedBox(
                                        width:
                                            8), // Space between icon and text
                                    Text(
                                      'Apply',
                                      style: TextStyle(
                                          fontSize:
                                              16), // Increase text size here
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}
