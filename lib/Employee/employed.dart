import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Employee/detail.dart';
import 'package:flutter_application_1/Employer/employer_registration_form.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class EmployedListScreen extends StatefulWidget {
  @override
  _EmployedListScreenState createState() => _EmployedListScreenState();
}

class _EmployedListScreenState extends State<EmployedListScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _employeeRef =
      FirebaseDatabase.instance.reference().child('employeeTable');
  final DatabaseReference _jobsRef =
      FirebaseDatabase.instance.reference().child('jobs');
  late DatabaseReference _employeesRef;
  List<Map<String, dynamic>> _employees = [];
  List<String> _employeeKeys = [];
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _employeesRef = _employeeRef;
    _fetchEmployees();

    // Initialize animation controller for rotating progress indicator
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _fetchEmployees() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userEmail = currentUser.email;

    _employeesRef
        .orderByChild('contactEmail')
        .equalTo(userEmail)
        .onValue
        .listen((event) async {
      final data = event.snapshot.value;
      final List<Map<String, dynamic>> loadedEmployees = [];
      final List<String> employeeKeys = [];

      if (data != null) {
        final Map<dynamic, dynamic> employeesMap =
            data as Map<dynamic, dynamic>;

        for (var entry in employeesMap.entries) {
          final dynamic employeeDynamic = entry.value;
          final Map<String, dynamic> employee =
              Map<String, dynamic>.from(employeeDynamic);
          final jobId = employee['jobId'];
          final employeeId = entry.key as String;

          // Check if status is 1
          if (employee['status'] == 1) {
            employeeKeys.add(employeeId);

            if (jobId != null) {
              final employeeWithJob = await _fetchJobDetails(jobId, employee);
              loadedEmployees.add(employeeWithJob);
            } else {
              loadedEmployees.add(employee);
            }
          }
        }

        setState(() {
          _employees = loadedEmployees;
          _employeeKeys = employeeKeys;
        });
      }
    });
  }

  Future<Map<String, dynamic>> _fetchJobDetails(
      String jobId, Map<String, dynamic> employee) async {
    final jobSnapshot = await _jobsRef.child(jobId).once();
    final jobData = jobSnapshot.snapshot.value as Map<dynamic, dynamic>?;

    if (jobData != null) {
      return {
        ...employee,
        'jobTitle': jobData['name'] ?? 'No title',
        'jobDescription': jobData['description'] ?? 'No description',
        'salary': _formatSalary(jobData['salary'], jobData['currency']),
        'location': jobData['location'] ?? 'No location',
        'status': jobData['status'] ?? 'No status',
      };
    } else {
      return Map<String, dynamic>.from(employee);
    }
  }

  String _formatSalary(dynamic salary, dynamic currency) {
    if (salary is num) {
      final formatter = NumberFormat('#,##0');
      String formattedSalary = formatter.format(salary);
      String currencyStr = currency is String ? currency : '';
      return '$formattedSalary $currencyStr';
    }
    return 'No salary';
  }

  void _approveEmployee(String employeeId) async {
    try {
      final employeeSnapshot = await _employeeRef.child(employeeId).once();
      final employeeData =
          employeeSnapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (employeeData != null) {
        if (employeeData.containsKey('name') &&
            employeeData['name'] is String) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeDataScreen(
              
                employeeId: employeeId,
              ),
            ),
          );
        } else {
          _showSnackBar('Employee data is invalid or incomplete');
        }
      } else {
        _showSnackBar('Employee not found');
      }
    } catch (error) {
      _showSnackBar('Failed to fetch employee details: $error');
    }
  }

  void _rejectEmployee(String employeeId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Rejection'),
          content: Text(
              'Are you sure you want to reject this employee? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteEmployee(employeeId);
                Navigator.of(context).pop();
              },
              child: Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  void _deleteEmployee(String employeeId) {
    _employeeRef.child(employeeId).remove().then((_) {
      _showSnackBar('Employee rejected and deleted');
    }).catchError((error) {
      _showSnackBar('Failed to delete employee: $error');
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Employee'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          },
        ),
      ),
      body: _employees.isEmpty
          ? _buildShimmerLoading()
          : ListView.builder(
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final employee = _employees[index];
                final employeeId = _employeeKeys[index];

                return Card(
                  margin: EdgeInsets.all(12),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: employee['profilePicture'] !=
                                          null
                                      ? NetworkImage(employee['profilePicture'])
                                      : AssetImage('assets/default_avatar.png')
                                          as ImageProvider,
                                  child: employee['profilePicture'] == null
                                      ? Icon(Icons.person, size: 35)
                                      : null,
                                ),
                                if (employee['profilePicture'] != null)
                                  Positioned.fill(
                                    child: Center(
                                      child: RotationTransition(
                                        turns: _rotationController,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 4,
                                          backgroundColor:
                                              Colors.teal.withOpacity(0.2),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    employee['name'] ?? 'No name',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.teal[800],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Email: ${employee['email'] ?? 'No email'}',
                                    style: TextStyle(color: Colors.teal[600]),
                                  ),
                                  Text(
                                    'Phone: ${employee['phone'] ?? 'No phone'}',
                                    style: TextStyle(color: Colors.teal[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Divider(thickness: 1),
                        SizedBox(height: 8),
                        _buildInfoRow(
                            Icons.person, 'Gender', employee['gender']),
                        _buildInfoRow(
                            Icons.home, 'Address', employee['address']),
                        _buildInfoRow(Icons.description, 'Description',
                            employee['resume']),
                        SizedBox(height: 16),
                        if (employee['frontIdCard'] != null)
                          _buildIdCard(
                              'Front ID Card', employee['frontIdCard']),
                        if (employee['backIdCard'] != null)
                          _buildIdCard('Back ID Card', employee['backIdCard']),
                        SizedBox(height: 16),
                        Divider(thickness: 1),
                        SizedBox(height: 8),
                        Text(
                          'Position: ${employee['jobTitle'] ?? 'No job title'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[700],
                          ),
                        ),
                        Text(
                          'Job Description: ${employee['jobDescription'] ?? 'No job description'}',
                          style: TextStyle(color: Colors.teal[600]),
                        ),
                        Text(
                          'Salary: ${employee['salary'] ?? 'No salary'}',
                          style: TextStyle(color: Colors.teal[600]),
                        ),
                        Text(
                          'Location: ${employee['location'] ?? 'No location'}',
                          style: TextStyle(color: Colors.teal[600]),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _approveEmployee(employeeId),
                              icon: Icon(Icons.history, color: Colors.white),
                              label: Text(
                                'Detail',
                                style: TextStyle(
                                    fontSize: 20), // Increase text size here
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _rejectEmployee(employeeId),
                              icon: Icon(Icons.cancel, color: Colors.white),
                              label: Text(
                                'Reject',
                                style: TextStyle(
                                    fontSize: 20), // Increase text size here
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 5, // Number of skeleton loaders
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Card(
              margin: EdgeInsets.all(0),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey.shade300,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            color: Colors.grey.shade300,
                            height: 20,
                            width: double.infinity,
                          ),
                          SizedBox(height: 8),
                          Container(
                            color: Colors.grey.shade300,
                            height: 14,
                            width: double.infinity * 0.6,
                          ),
                          SizedBox(height: 4),
                          Container(
                            color: Colors.grey.shade300,
                            height: 14,
                            width: double.infinity * 0.5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal[600]),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: ${value ?? 'Not available'}',
            style: TextStyle(color: Colors.teal[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildIdCard(String title, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity, // Makes the container as wide as possible
          height: 200, // Fixed height for the image
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  } else {
                    double progress = loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1);
                    int percentage = (progress * 100).toInt();

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          backgroundColor: Colors.teal.withOpacity(0.2),
                        ),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
