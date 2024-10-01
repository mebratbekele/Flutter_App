import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Employer/employer_registration_form.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class SellerBuyerAfterLinkDisplayScreen extends StatefulWidget {
  @override
  _SellerBuyerAfterLinkDisplayScreenState createState() =>
      _SellerBuyerAfterLinkDisplayScreenState();
}

class _SellerBuyerAfterLinkDisplayScreenState
    extends State<SellerBuyerAfterLinkDisplayScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _sellersRef =
      FirebaseDatabase.instance.reference().child('sellers');
  final DatabaseReference _buyersRef =
      FirebaseDatabase.instance.reference().child('buyers');
  late DatabaseReference _sellerRef;
  List<Map<String, dynamic>> _sellers = [];
  List<String> _sellerKeys = [];
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _sellerRef = _sellersRef;
    _fetchSellers();

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

  void _fetchSellers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userEmail = currentUser.email;

    _sellerRef
        .orderByChild('userEmail')
        .equalTo(userEmail)
        .onValue
        .listen((event) async {
      final data = event.snapshot.value;
      final List<Map<String, dynamic>> loadedSellers = [];
      final List<String> sellerKeys = [];

      if (data != null) {
        final Map<dynamic, dynamic> sellersMap = data as Map<dynamic, dynamic>;

        for (var entry in sellersMap.entries) {
          final dynamic sellersDynamic = entry.value;
          final Map<String, dynamic> seller =
              Map<String, dynamic>.from(sellersDynamic);
          final buyerId = seller['buyerId'];
          final sellerId = entry.key as String;

          if (seller['status'] == '1') {
            sellerKeys.add(sellerId);

            if (buyerId != null) {
              final sellerWithBuyer = await _fetchJobDetails(buyerId, seller);
              loadedSellers.add(sellerWithBuyer);
            } else {
              loadedSellers.add(seller);
            }
          }
        }

        setState(() {
          _sellers = loadedSellers;
          _sellerKeys = sellerKeys;
        });
      }
    });
  }

  Future<Map<String, dynamic>> _fetchJobDetails(
      String buyerId, Map<dynamic, dynamic> seller) async {
    final jobSnapshot = await _buyersRef.child(buyerId).once();
    final buyerData = jobSnapshot.snapshot.value as Map<dynamic, dynamic>?;

    if (buyerData != null) {
      return {
        ...seller,
        'buyerFullName': buyerData['fullName'] ?? 'No fullName',
        'buyerEmail': buyerData['email'] ?? 'No email',
        'buyerPhone': buyerData['phone'] ?? 'No phone',
        'buyerAddress': buyerData['address'] ?? 'No address',
        'buyerItemName': buyerData['itemName'] ?? 'No itemName',
        'buyerItemCost':
            _formatItemCost(buyerData['itemCost'], buyerData['currency']),
        'buyerPaymentMethod': buyerData['paymentMethod'] ?? 'No payment method',
        'buyerDescription': buyerData['description'] ?? 'No description',
        'buyerItemPhotos':
            buyerData['itemPhotos'] ?? [], // Expecting a list of photos
        'buyerSellerId': buyerData['selerId'] ?? 'No sellerId',
      };
    } else {
      return Map<String, dynamic>.from(seller);
    }
  }

  String _formatItemCost(dynamic cost, dynamic currency) {
    if (cost is num) {
      final formatter = NumberFormat('#,##0');
      String formattedCost = formatter.format(cost);
      String currencyStr = currency is String ? currency : '';
      return '$formattedCost $currencyStr';
    }
    return 'No ItemCost';
  }

  void _approveEmployee(String employeeId) async {
    try {
      final employeeSnapshot = await _sellersRef.child(employeeId).once();
      final employeeData =
          employeeSnapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (employeeData != null) {
        if (employeeData.containsKey('name') &&
            employeeData['name'] is String) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployerRegistrationForm(
                employee: Map<String, dynamic>.from(employeeData),
                employeeId: employeeId,
              ),
            ),
          );
        } else {
          _showSnackBar('Seller data is invalid or incomplete');
        }
      } else {
        _showSnackBar('Seller not found');
      }
    } catch (error) {
      _showSnackBar('Failed to fetch seller details: $error');
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
    _sellersRef.child(employeeId).remove().then((_) {
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
        title: Text('Seller & Buyer'),
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
      body: _sellers.isEmpty
          ? _buildShimmerLoading()
          : ListView.builder(
              itemCount: _sellers.length,
              itemBuilder: (context, index) {
                final seller = _sellers[index];
                final employeeId = _sellerKeys[index];

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
                                  backgroundImage: seller['profilePicture'] !=
                                          null
                                      ? NetworkImage(seller['profilePicture'])
                                      : AssetImage('assets/default_avatar.png')
                                          as ImageProvider,
                                  child: seller['profilePicture'] == null
                                      ? Icon(Icons.person, size: 35)
                                      : null,
                                ),
                                if (seller['profilePicture'] != null)
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
                                    'Seller Details: \n${seller['fullName'] is String ? seller['fullName'] : 'No fullName'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Email: ${seller['email'] is String ? seller['email'] : 'No email'}',
                                    style: TextStyle(color: Colors.teal[600]),
                                  ),
                                  Text(
                                    'Phone: ${seller['phone'] is String ? seller['phone'] : 'No phone'}',
                                    style: TextStyle(color: Colors.teal[600]),
                                  ),
                                  Text(
                                    'Address: ${seller['address'] is String ? seller['address'] : 'No address'}',
                                    style: TextStyle(color: Colors.teal[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Divider(thickness: 1),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Item Details:',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyan)),
                        ),
                        SizedBox(height: 8),
                        _buildInfoRow(
                            Icons.person,
                            'Item Name',
                            seller['itemName'] is String
                                ? seller['itemName']
                                : 'Not available'),
                        _buildInfoRow(
                          Icons.money,
                          'Item Cost',
                          (seller['itemCost'] is String
                                  ? seller['itemCost']
                                  : 'No cost') +
                              (seller['currency'] is String
                                  ? ' ${seller['currency']}'
                                  : ' No currency'),
                        ),
                        _buildInfoRow(
                            Icons.payment,
                            'Payment Method',
                            seller['paymentMethod'] is String
                                ? seller['paymentMethod']
                                : 'Not specified'),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Description:',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyan)),
                        ),
                        Container(
                          height: 100, // Set height for scrollable area
                          child: SingleChildScrollView(
                            child: Text(
                              seller['description'] is String
                                  ? seller['description']
                                  : 'Not specified',
                              style: TextStyle(color: Colors.teal[600]),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Item Photos:',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyan)),
                        ),
                        Container(
                          height: 100, // Set height for photo display
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: seller['buyerItemPhotos'].length,
                            itemBuilder: (context, photoIndex) {
                              final photoUrl =
                                  seller['buyerItemPhotos'][photoIndex];
                              return Container(
                                width: 100,
                                margin: EdgeInsets.symmetric(horizontal: 4.0),
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                        child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(child: Icon(Icons.error));
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 16),
                        Divider(thickness: 1),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Buyer Detail',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyan)),
                        ),
                        SizedBox(height: 8),
                        _buildInfoRow(
                            Icons.person,
                            'Full Name:',
                            seller['buyerFullName'] is String
                                ? seller['buyerFullName']
                                : 'Not buyerFullName'),
                        _buildInfoRow(
                            Icons.phone,
                            'Phone:',
                            seller['buyerPhone'] is String
                                ? seller['buyerPhone']
                                : 'Not buyerPhone'),
                        _buildInfoRow(
                            Icons.email,
                            'Email:',
                            seller['buyerEmail'] is String
                                ? seller['buyerEmail']
                                : 'Not buyerEmail'),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _approveEmployee(employeeId),
                              child: Text('Approve'),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.green),
                            ),
                            TextButton(
                              onPressed: () => _rejectEmployee(employeeId),
                              child: Text('Reject'),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
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

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal),
        SizedBox(width: 8),
        Text('$title: $value'),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            height: 100,
            margin: EdgeInsets.all(12),
            color: Colors.white,
          );
        },
      ),
    );
  }
}
