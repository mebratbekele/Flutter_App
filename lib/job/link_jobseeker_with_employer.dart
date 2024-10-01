import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class JobseekerLinkWithEmployerScreen extends StatefulWidget {
  @override
  _JobseekerLinkWithEmployerScreenState createState() =>
      _JobseekerLinkWithEmployerScreenState();
}

class _JobseekerLinkWithEmployerScreenState
    extends State<JobseekerLinkWithEmployerScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _employeeRef =
      FirebaseDatabase.instance.ref().child('employeeTable');
  final DatabaseReference _jobsRef =
      FirebaseDatabase.instance.ref().child('jobs');

  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _filteredJobs = [];
  String? _selectedEmployeeId;
  String? _selectedJobId;
  late AnimationController _rotationController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _fetchJobs();

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

    _employeeRef
        .orderByChild('contactEmail')
        .equalTo(userEmail)
        .onValue
        .listen((event) {
      final data = event.snapshot.value;

      if (data != null) {
        final Map<dynamic, dynamic> employeesMap =
            data as Map<dynamic, dynamic>;

        final List<Map<String, dynamic>> loadedEmployees = [];
        for (var entry in employeesMap.entries) {
          final dynamic employeeDynamic = entry.value;
          final Map<String, dynamic> employee =
              Map<String, dynamic>.from(employeeDynamic);

          if (employee['status'] == "request") {
            loadedEmployees.add({
              'id': entry.key,
              ...employee,
            });
          }
        }

        setState(() {
          _employees = loadedEmployees;
        });
      }
    }).onError((error) {
      print('Error fetching employees: $error');
    });
  }

  void _fetchJobs() async {
    _jobsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      final List<Map<String, dynamic>> loadedJobs = [];

      if (data != null) {
        final Map<dynamic, dynamic> jobsMap = data as Map<dynamic, dynamic>;

        for (var entry in jobsMap.entries) {
          final dynamic jobDynamic = entry.value;
          final Map<String, dynamic> job =
              Map<String, dynamic>.from(jobDynamic);

          if (job['status'] is int && job['status'] == 0) {
            loadedJobs.add({
              'id': entry.key,
              ...job,
            });
          }
        }

        setState(() {
          _jobs = loadedJobs;
          _filteredJobs = loadedJobs; // Initialize filtered jobs
        });
      }
    }).onError((error) {
      print('Error fetching jobs: $error');
    });
  }

  void _filterJobs(String query) {
    setState(() {
      _searchQuery = query;
      _filteredJobs = _jobs.where((job) {
        final jobName = job['name'].toLowerCase();
        return jobName.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _submitSelection() {
    if (_selectedEmployeeId != null && _selectedJobId != null) {
      print('Selected Employee ID: $_selectedEmployeeId');
      print('Selected Job ID: $_selectedJobId');

      // Update the employee's jobId and status
      _employeeRef.child(_selectedEmployeeId!).update({
        'jobId': _selectedJobId,
        'status': '0', // Assuming status is stored as a string
      }).then((_) {
        print('Employee updated successfully.');
      }).catchError((error) {
        print('Failed to update employee: $error');
      });

      // Update the job's status
      _jobsRef.child(_selectedJobId!).update({
        'status': 0, // Assuming status is stored as an integer
      }).then((_) {
        print('Job updated successfully.');
      }).catchError((error) {
        print('Failed to update job: $error');
      });
    } else {
      print('Please select both an employee and a job.');
    }
  }

  void _showEmployeeDetails(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Details for ${employee['name']}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                if (employee['profilePicture'] != null)
                  Image.network(employee['profilePicture']),
                if (employee['frontIdCard'] != null)
                  Image.network(employee['frontIdCard']),
                if (employee['backIdCard'] != null)
                  Image.network(employee['backIdCard']),
                Text('Address: ${employee['address'] ?? 'No address'}'),
                Text('Gender: ${employee['gender'] ?? 'No gender'}'),
                Text('Phone: ${employee['phone'] ?? 'No phone'}'),
                Text('Email: ${employee['contactEmail'] ?? 'No email'}'),
                Text('Required: ${employee['resume'] ?? 'No resume'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jobseeker and Job Listings'),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 600;
          return Row(
            children: [
              Expanded(
                flex: isWideScreen ? 2 : 1,
                child: _employees.isEmpty
                    ? _buildShimmerLoading()
                    : ListView.builder(
                        itemCount: _employees.length,
                        itemBuilder: (context, index) {
                          final employee = _employees[index];
                          final employeeId = employee['id'] as String;
                          return Card(
                            margin: EdgeInsets.all(8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Radio<String>(
                                value: employeeId,
                                groupValue: _selectedEmployeeId,
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedEmployeeId = value;
                                  });
                                },
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(employee['name'] ?? 'No name',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      )),
                                  Text(employee['resume'] ?? 'No Description'),
                                  SizedBox(height: 10),
                                  TextButton(
                                    onPressed: () {
                                      _showEmployeeDetails(employee);
                                    },
                                    child: Text('Details'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (isWideScreen) VerticalDivider(width: 1, color: Colors.grey),
              Expanded(
                flex: isWideScreen ? 3 : 1,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Search Jobs',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _filterJobs,
                      ),
                    ),
                    Expanded(
                      child: _filteredJobs.isEmpty
                          ? _buildShimmerLoading()
                          : ListView.builder(
                              itemCount: _filteredJobs.length,
                              itemBuilder: (context, index) {
                                final job = _filteredJobs[index];
                                final jobId = job['id'] as String;

                                return Card(
                                  margin: EdgeInsets.all(8),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: Radio<String>(
                                      value: jobId,
                                      groupValue: _selectedJobId,
                                      onChanged: (String? value) {
                                        setState(() {
                                          _selectedJobId = value;
                                        });
                                      },
                                    ),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(job['name'] ?? 'No title',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            )),
                                        Text('Salary: ' +
                                            (job['salary']?.toString() ??
                                                'No salary') +
                                            ' ' +
                                            (job['currency'] ?? 'No currency')),
                                        Text('Required Gender: ' +
                                            (job['gender'] ?? 'No gender')),
                                        Text('Address: ' +
                                            (job['location'] ?? 'No address')),
                                        Text('Description: ' +
                                            (job['description'] ??
                                                'No description')),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitSelection,
        child: Icon(Icons.check),
        backgroundColor: Colors.teal,
        tooltip: 'Submit Selection',
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Card(
              margin: EdgeInsets.all(0),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
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
}
