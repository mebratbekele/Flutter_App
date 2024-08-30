class Job {
  final String jobId;
  final String userEmail;
  final String name;
  final double salary;
  final String currency;
  final String location;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? gender;
  final int numberRequired;
  final int status;
  final DateTime? postDate; // Optional
  final DateTime? startDate; // Optional
  final DateTime? endDate; // Optional

  Job({
    required this.jobId,
    required this.userEmail,
    required this.name,
    required this.salary,
    required this.currency,
    required this.location,
    required this.description,
    this.latitude,
    this.longitude,
    this.gender,
    required this.numberRequired,
    this.status = 0,
    this.postDate,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'userEmail': userEmail,
      'name': name,
      'salary': salary,
      'currency': currency,
      'location': location,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'gender': gender,
      'numberRequired': numberRequired,
      'status': status,
      'postDate': postDate?.toIso8601String(), // Convert to string
      'startDate': startDate?.toIso8601String(), // Convert to string
      'endDate': endDate?.toIso8601String(), // Convert to string
    };
  }

  Job.fromMap(Map<String, dynamic> map)
      : jobId = map['jobId'],
        userEmail = map['userEmail'],
        name = map['name'],
        salary = map['salary'],
        currency = map['currency'],
        location = map['location'],
        description = map['description'],
        latitude = map['latitude'],
        longitude = map['longitude'],
        gender = map['gender'],
        numberRequired = map['numberRequired'],
        status = map['status'] ?? 0,
        postDate = map['postDate'] != null ? DateTime.parse(map['postDate']) : null,
        startDate = map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
        endDate = map['endDate'] != null ? DateTime.parse(map['endDate']) : null;
}
