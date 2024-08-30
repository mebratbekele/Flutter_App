import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class EmployeeDataScreen extends StatelessWidget {
  final String employeeId;

  EmployeeDataScreen({required this.employeeId});

  Future<Map<String, dynamic>?> fetchEmployeeData(String employeeId) async {
    final databaseReference = FirebaseDatabase.instance.ref();
    DatabaseEvent event =
        await databaseReference.child('employerTable').child(employeeId).once();

    DataSnapshot snapshot = event.snapshot;
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employer and Guarantor Details'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchEmployeeData(employeeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(
                child: Text('No data found for employee ID: $employeeId'));
          } else {
            final data = snapshot.data!;
            final images = [
              {
                'url': data['employerIdCardFront'] as String?,
                'label': 'Guarantor ID Card Front Side'
              },
              {
                'url': data['employerIdCardBack'] as String?,
                'label': 'Guarantor ID Card Back Side'
              },
              {
                'url': data['employerSignature'] as String?,
                'label': 'Employer Signature'
              },
              {
                'url': data['emergencySignature'] as String?,
                'label': 'Guarantor Signature'
              },
              {
                'url': data['employeeSignature'] as String?,
                'label': 'Employee Signature'
              },
            ]
                .where((item) => item['url'] != null && item['url']!.isNotEmpty)
                .toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildSectionTitle(
                      'Employer Information\n For Employee ID: $employeeId'),
                  _buildProfileHeader(data['employerProfilePicture'] as String?,
                      data['employerFullName'] as String?),
                  _buildDetailTile(
                      'Full Name', data['employerFullName'] as String?),
                  _buildDetailTile('Email', data['employerEmail'] as String?),
                  _buildDetailTile('Phone', data['employerPhone'] as String?),
                  _buildDetailTile('Gender', data['employerGender'] as String?),
                  SizedBox(height: 16.0),
                  _buildSectionTitle(
                      'Guarantor (Emergency Contact) Information\nFor Employee ID: $employeeId'),
                  _buildDetailTile('Guarantor Full Name',
                      data['employerEmergencyFullName'] as String?),
                  _buildDetailTile('Guarantor Phone',
                      data['employerEmergencyPhone'] as String?),
                  _buildDetailTile('Guarantor Address',
                      data['employerEmergencyAddress'] as String?),
                  _buildDetailTile('Guarantor Email',
                      data['employerEmergencyEmail'] as String?),
                  SizedBox(height: 16.0),
                  _buildSectionTitle('Documents and Signature'),
                  _buildImageList(images),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileHeader(String? imageUrl, String? fullName) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.teal[100],
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 50,
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImageProvider(imageUrl)
                : AssetImage('assets/default_avatar.png') as ImageProvider,
            backgroundColor: Colors.white,
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  fullName ?? 'No Name',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Profile Picture',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
      ),
    );
  }

  Widget _buildDetailTile(String title, String? value) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.0),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value ?? 'N/A'),
        leading: Icon(Icons.info_outline, color: Colors.teal),
      ),
    );
  }

  Widget _buildImageList(List<Map<String, String?>> images) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: images.map((item) {
          final imageUrl = item['url'];
          final label = item['label'];
          if (imageUrl != null && imageUrl.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child:
                            Center(child: Icon(Icons.error, color: Colors.red)),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    label ?? 'No Label',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          } else {
            return SizedBox
                .shrink(); // Empty widget if image URL is null or empty
          }
        }).toList(),
      ),
    );
  }
}
