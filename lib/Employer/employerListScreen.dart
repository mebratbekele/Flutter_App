import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EmployerDetailsPage extends StatefulWidget {
  @override
  _EmployerDetailsPageState createState() => _EmployerDetailsPageState();
}

class _EmployerDetailsPageState extends State<EmployerDetailsPage> {
  final _searchController = TextEditingController();
  Future<Map<String, Map<String, dynamic>>>? _searchResultFuture;
  Map<String, Map<String, dynamic>> _allEmployers = {};

  @override
  void initState() {
    super.initState();
    _fetchEmployerDetails();
  }

  Future<void> _fetchEmployerDetails() async {
    final databaseReference =
        FirebaseDatabase.instance.ref().child('employerTable');
    final DatabaseEvent event = await databaseReference.once();

    if (event.snapshot.exists) {
      final data = event.snapshot.value as Map<Object?, Object?>?;
      if (data != null) {
        setState(() {
          _allEmployers = Map<String, Map<String, dynamic>>.from(data.map(
              (key, value) => MapEntry(key.toString(),
                  Map<String, dynamic>.from(value as Map<Object?, Object?>))));
        });
      }
    }
  }

  Future<Map<String, Map<String, dynamic>>> _searchEmployerByQuery(
      String query) async {
    final lowerQuery = query.toLowerCase();
    final filteredEmployers = _allEmployers.entries.where((entry) {
      final employer = entry.value;
      final phone = employer['employerPhone']?.toLowerCase() ?? '';
      final email = employer['employerEmail']?.toLowerCase() ?? '';
      return phone.contains(lowerQuery) || email.contains(lowerQuery);
    });

    return Map.fromEntries(filteredEmployers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employer Details'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by phone or email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _searchResultFuture =
                          _searchEmployerByQuery(_searchController.text);
                    });
                  },
                  child: Text('Search'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, Map<String, dynamic>>>(
              future: _searchResultFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final employers = snapshot.data!;
                  if (employers.isEmpty) {
                    return Center(child: Text('No results found'));
                  }
                  return SingleChildScrollView(
                    child: Column(
                      children: employers.entries.map((entry) {
                        final employerId = entry.key;
                        final employer = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundImage: employer[
                                                    'employerProfilePicture'] !=
                                                null
                                            ? NetworkImage(employer[
                                                'employerProfilePicture'])
                                            : AssetImage(
                                                    'assets/default_avatar.png')
                                                as ImageProvider,
                                        backgroundColor: Colors.grey[200],
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'ID: $employerId',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '${employer['employerFullName'] ?? 'N/A'}',
                                              style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  _buildDetailRow('Email:',
                                      employer['employerEmail'] ?? 'N/A'),
                                  _buildDetailRow('Phone:',
                                      employer['employerPhone'] ?? 'N/A'),
                                  _buildDetailRow('Gender:',
                                      employer['employerGender'] ?? 'N/A'),
                                  _buildDetailRow('Address:',
                                      employer['employerAddress'] ?? 'N/A'),
                                  _buildDetailRow(
                                      'Emergency Contact Full Name:',
                                      employer['employerEmergencyFullName'] ??
                                          'N/A'),
                                  _buildDetailRow(
                                      'Emergency Contact Phone:',
                                      employer['employerEmergencyPhone'] ??
                                          'N/A'),
                                  _buildDetailRow(
                                      'Emergency Contact Address:',
                                      employer['employerEmergencyAddress'] ??
                                          'N/A'),
                                  _buildDetailRow(
                                      'Emergency Contact Email:',
                                      employer['employerEmergencyEmail'] ??
                                          'N/A'),
                                  SizedBox(height: 16),
                                  if (employer['employerIdCardFront'] != null)
                                    _buildImageSection('ID Card Front',
                                        employer['employerIdCardFront']),
                                  if (employer['employerIdCardBack'] != null)
                                    _buildImageSection('ID Card Back',
                                        employer['employerIdCardBack']),
                                  if (employer['employerSignature'] != null)
                                    _buildImageSection('Signature',
                                        employer['employerSignature']),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                } else {
                  return Center(child: Text('No data available'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(String title, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 8),
          Container(
            width: double
                .infinity, // Makes the container take up 100% of the width
            child: Image.network(
              imageUrl,
              fit: BoxFit
                  .fitWidth, // Ensures the image fits the width of the container
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}
