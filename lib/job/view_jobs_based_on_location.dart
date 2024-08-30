import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/job/post.dart';
import 'package:intl/intl.dart'; // Import intl package for number formatting

class JobListBasedOnLocation extends StatefulWidget {
  @override
  _JobListBasedOnLocationState createState() => _JobListBasedOnLocationState();
}

class _JobListBasedOnLocationState extends State<JobListBasedOnLocation> {
  final DatabaseReference _jobsRef =
      FirebaseDatabase.instance.ref().child('jobs');
  bool _isLoading = true;
  List<Map<dynamic, dynamic>> _jobs = [];
  List<Map<dynamic, dynamic>> _filteredJobs = [];
  final TextEditingController _searchController = TextEditingController();
  late String _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _getUserEmail();
    _searchController.addListener(_filterJobs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserEmail = user.email ?? '';
      });
      _fetchJobs(); // Fetch jobs after getting user email
    } else {
      print('User not logged in.');
      _currentUserEmail = ''; // Handle as needed
    }
  }

  Future<void> _fetchJobs() async {
    try {
      final snapshot = await _jobsRef.once();
      if (snapshot.snapshot.exists) {
        final jobs = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        setState(() {
          _jobs = jobs.entries
              .where((entry) =>
                  (entry.value['userEmail'] ?? '') == _currentUserEmail)
              .map((entry) => {
                    'id': entry.key, // Assuming the key is the unique job ID
                    ...entry.value,
                  })
              .toList()
              .cast<Map<dynamic, dynamic>>();
          _filteredJobs = _jobs; // Initially, show all jobs
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
    });
  }

  Future<void> _editJob(String jobId) async {
    if (jobId.isNotEmpty) {
      final job = _jobs.firstWhere((job) => job['id'] == jobId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JobForm(
              // jobId: jobId,
              // jobData: job,
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid job ID.')),
      );
    }
  }

  Future<void> _deleteJob(String jobId) async {
    if (jobId.isNotEmpty) {
      try {
        await _jobsRef.child(jobId).remove();
        _fetchJobs(); // Refresh the job list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job deleted successfully.')),
        );
      } catch (e) {
        print('Error deleting job: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting job.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid job ID.')),
      );
    }
  }

  void _showDeleteConfirmationDialog(String jobId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Job'),
          content: Text('Are you sure you want to delete this job?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteJob(jobId);
              },
              child: Text('Delete'),
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
        title: Text('View Jobs'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          },
        ),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              icon: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.add,
                  color: Colors.blue, // Customize icon color here
                ),
              ),
              label: Text(
                'Post Job',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Customize text color here
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Customize background color here
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      8.0), // Customize border radius here
                ),
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JobForm()),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
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
                          final jobId = job['id'] as String? ?? '';
                          final salary = job['salary'] as num? ?? 0;
                          final currency = job['currency'] ?? 'No currency';

                          // Create a NumberFormat instance for formatting the salary with commas
                          final numberFormat = NumberFormat('#,##0', 'en_US');
                          final formattedSalary = numberFormat.format(salary);

                          // Determine the job status
                          final status = (job['status'] ?? 0) == 1
                              ? 'Completed'
                              : 'Pending';

                          return Card(
                            elevation: 4,
                            margin: EdgeInsets.all(8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Icon(
                                      Icons.work,
                                      color: Colors.white,
                                    ),
                                    radius: 30,
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          job['name'] ?? 'No Job Name',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Salary: $formattedSalary $currency',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Location: ${job['location'] ?? 'No Location'}',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700]),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Gender: ${job['gender'] ?? 'No gender'}',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700]),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Required Number: ${job['numberRequired'] ?? 'No required'}',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700]),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Description: ${job['description'] ?? 'No Description'}',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700]),
                                        ),
                                        SizedBox(height: 8),
                                        // Display the status
                                        Text(
                                          'Status: $status',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: status == 'Completed'
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                if (jobId.isNotEmpty) {
                                                  _editJob(jobId);
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor: Colors
                                                    .green, // Button color
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.edit,
                                                      color: Colors
                                                          .white), // Prefix icon
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () {
                                                if (jobId.isNotEmpty) {
                                                  _showDeleteConfirmationDialog(
                                                      jobId);
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor:
                                                    Colors.red, // Button color
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.delete,
                                                      color: Colors
                                                          .white), // Prefix icon
                                                  SizedBox(width: 8),
                                                  Text('Delete'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

// Example EditJobScreen widget
class EditJobScreen extends StatelessWidget {
  final String jobId;

  EditJobScreen({required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Job'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text('Edit job with ID: $jobId'),
      ),
    );
  }
}
