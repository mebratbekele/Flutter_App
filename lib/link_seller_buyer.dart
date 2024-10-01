import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shimmer/shimmer.dart';

class SellerBuyerLinkScreen extends StatefulWidget {
  @override
  _SellerBuyerLinkScreenState createState() => _SellerBuyerLinkScreenState();
}

class _SellerBuyerLinkScreenState extends State<SellerBuyerLinkScreen> {
  final DatabaseReference _sellersRef =
      FirebaseDatabase.instance.ref().child('sellers');
  final DatabaseReference _buyersRef =
      FirebaseDatabase.instance.ref().child('buyers');

  List<Map<String, dynamic>> _sellers = [];
  List<Map<String, dynamic>> _filteredSellers = [];
  List<Map<String, dynamic>> _buyers = [];
  List<Map<String, dynamic>> _filteredBuyers = [];
  String? _selectedSellerId;
  String? _selectedBuyerId;
  String _buyerSearchQuery = '';
  String _sellerSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchSellers();
    _fetchBuyers();
  }

  void _fetchSellers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userEmail = currentUser.email;

    _sellersRef
        .orderByChild('userEmail')
        .equalTo(userEmail)
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      final List<Map<String, dynamic>> loadedSellers = [];

      if (data != null) {
        final Map<dynamic, dynamic> sellersMap = data as Map<dynamic, dynamic>;
        for (var entry in sellersMap.entries) {
          final dynamic sellerDynamic = entry.value;
          final Map<String, dynamic> seller =
              Map<String, dynamic>.from(sellerDynamic);

          if (seller['status'] == 0) {
            loadedSellers.add({'id': entry.key, ...seller});
          }
        }

        setState(() {
          _sellers = loadedSellers;
          _filteredSellers = loadedSellers; // Initialize filtered list
        });
      }
    });
  }

  void _fetchBuyers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userEmail = currentUser.email;

    _buyersRef
        .orderByChild('userEmail')
        .equalTo(userEmail)
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      final List<Map<String, dynamic>> loadedBuyers = [];

      if (data != null) {
        final Map<dynamic, dynamic> buyersMap = data as Map<dynamic, dynamic>;
        for (var entry in buyersMap.entries) {
          final dynamic buyerDynamic = entry.value;
          final Map<String, dynamic> buyer =
              Map<String, dynamic>.from(buyerDynamic);

          if (buyer['status'] == 0) {
            loadedBuyers.add({'id': entry.key, ...buyer});
          }
        }

        setState(() {
          _buyers = loadedBuyers;
          _filteredBuyers = loadedBuyers;
        });
      }
    });
  }

  void _filterBuyers(String query) {
    setState(() {
      _buyerSearchQuery = query;
      _filteredBuyers = _buyers.where((buyer) {
        final fullNameMatch =
            buyer['fullName'].toLowerCase().contains(query.toLowerCase());
        final addressMatch =
            buyer['address'].toLowerCase().contains(query.toLowerCase());
        return fullNameMatch || addressMatch;
      }).toList();
    });
  }

  void _filterSellers(String query) {
    setState(() {
      _sellerSearchQuery = query;
      _filteredSellers = _sellers.where((seller) {
        return seller['address'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _submitSelection() {
    if (_selectedSellerId != null && _selectedBuyerId != null) {
      // Show dialog for selected seller and buyer IDs

      // Update seller info
      _sellersRef.child(_selectedSellerId!).update({
        'buyerId': _selectedBuyerId,
        'status': '1', // Assuming status is stored as a string
      }).then((_) {
        // _showDialog('Seller link Buyer successfully.');
      }).catchError((error) {
        _showDialog('Failed to Seller link Buyer: $error');
      });

      // Update buyer info
      _buyersRef.child(_selectedBuyerId!).update({
        'selerId': _selectedSellerId,
        'status': 1, // Assuming status is stored as an integer
      }).then((_) {
        _showDialog(
            'Selected Seller ID: $_selectedSellerId\nSelected Buyer ID: $_selectedBuyerId\nsuccessfully Linked ');
      }).catchError((error) {
        _showDialog('Failed to Buyer link Seller : $error');
      });
    } else {
      _showDialog('Please select both a seller and a buyer.');
    }
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Information'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showBuyerDetails(Map<String, dynamic> buyer) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Details for ${buyer['fullName']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item Details',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 8),
                if (buyer['itemPhoto'] is String &&
                    buyer['itemPhoto']!.isNotEmpty)
                  Image.network(buyer['itemPhoto']),
                Text('Item Name: ${buyer['itemName'] ?? 'No item name'}'),
                Text('Item Cost: ${buyer['itemCost'] ?? 'No item cost'}'),
                Text(
                    'Payment Method: ${buyer['paymentMethod'] ?? 'No description'}'),
                Divider(height: 20, color: Colors.grey),
                Text('Buyer Details',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 8),
                Text('Full Name: ${buyer['fullName'] ?? 'No full name'}'),
                Text('Phone: ${buyer['phone'] ?? 'No phone'}'),
                Text('Email: ${buyer['contactEmail'] ?? 'No email'}'),
                Text('Address: ${buyer['address'] ?? 'No address'}'),
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

  void _showSellerDetails(Map<String, dynamic> seller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Details for ${seller['fullName']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item Details',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 8),
                if (seller['itemPhoto'] is String &&
                    seller['itemPhoto']!.isNotEmpty)
                  Image.network(seller['itemPhoto']),
                Text('Item Name: ${seller['itemName'] ?? 'No item name'}'),
                Text('Item Cost: ${seller['itemCost'] ?? 'No item cost'}'),
                Text(
                    'Payment Method: ${seller['paymentMethod'] ?? 'No description'}'),
                Divider(height: 20, color: Colors.grey),
                Text('Seller Details',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 8),
                Text('Full Name: ${seller['fullName'] ?? 'No full name'}'),
                Text('Phone: ${seller['phone'] ?? 'No phone'}'),
                Text('Email: ${seller['contactEmail'] ?? 'No email'}'),
                Text('Address: ${seller['address'] ?? 'No address'}'),
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
        title: Text(
          'Requests',
          style: const TextStyle(
            color: Colors.orangeAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                blurRadius: 5.0,
                color: Colors.black,
                offset: Offset(2.0, 2.0),
              ),
            ],
            fontFamily: 'Roboto',
          ),
        ),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Seller',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyan)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Search Sellers by Address',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _filterSellers,
                      ),
                    ),
                    Expanded(
                      child: _filteredSellers.isEmpty
                          ? _buildShimmerLoading()
                          : ListView.builder(
                              itemCount: _filteredSellers.length,
                              itemBuilder: (context, index) {
                                final seller = _filteredSellers[index];
                                return Card(
                                  margin: EdgeInsets.all(8),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: Radio<String>(
                                      value: seller['id'],
                                      groupValue: _selectedSellerId,
                                      onChanged: (String? value) {
                                        setState(() {
                                          _selectedSellerId = value;
                                        });
                                      },
                                    ),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            seller['fullName'] ??
                                                'No full name',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        Text('Selling Item: ' +
                                            (seller['itemName'] ??
                                                'No item name')),
                                        SizedBox(height: 10),
                                        TextButton(
                                          onPressed: () {
                                            _showSellerDetails(seller);
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
                  ],
                ),
              ),
              if (isWideScreen) VerticalDivider(width: 1, color: Colors.grey),
              Expanded(
                flex: isWideScreen ? 3 : 1,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Buyer',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Search Buyers',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _filterBuyers,
                      ),
                    ),
                    Expanded(
                      child: _filteredBuyers.isEmpty
                          ? _buildShimmerLoading()
                          : ListView.builder(
                              itemCount: _filteredBuyers.length,
                              itemBuilder: (context, index) {
                                final buyer = _filteredBuyers[index];
                                return Card(
                                  margin: EdgeInsets.all(8),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: Radio<String>(
                                      value: buyer['id'],
                                      groupValue: _selectedBuyerId,
                                      onChanged: (String? value) {
                                        setState(() {
                                          _selectedBuyerId = value;
                                        });
                                      },
                                    ),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            buyer['fullName'] ?? 'No full name',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        Text('Buying Item: ' +
                                            (buyer['itemName'] ??
                                                'No item name')),
                                        SizedBox(height: 10),
                                        TextButton(
                                          onPressed: () {
                                            _showBuyerDetails(buyer);
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
