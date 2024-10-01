import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart'; // Import intl package for number formatting

class SellerDetailsScreen extends StatefulWidget {
  @override
  _SellerDetailsScreenState createState() => _SellerDetailsScreenState();
}

class _SellerDetailsScreenState extends State<SellerDetailsScreen> {
  final DatabaseReference databaseRef =
      FirebaseDatabase.instance.ref("sellers");
  List<Map<dynamic, dynamic>> sellers = [];
  List<Map<dynamic, dynamic>> filteredSellers = [];
  String searchQuery = '';
  double? currentLatitude;
  double? currentLongitude;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    fetchSellers();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentLatitude = position.latitude;
        currentLongitude = position.longitude;
      });
    } catch (e) {
      // Handle permission denied or any other exceptions
      print('Could not get current location: $e');
    }
  }

  Future<void> fetchSellers() async {
    databaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          sellers = data.entries
              .map((e) => e.value as Map<dynamic, dynamic>)
              .where((seller) =>
                  seller['status'] == 0) // Filter sellers with status = 0
              .toList();
          filteredSellers = sellers; // Initialize filtered sellers
          _sortSellersByDistance(); // Sort sellers by distance
        });
      }
    });
  }

  double calculateDistance(double? sellerLatitude, double? sellerLongitude) {
    if (currentLatitude == null ||
        currentLongitude == null ||
        sellerLatitude == null ||
        sellerLongitude == null) {
      return double.infinity; // Return a large number if any value is null
    }
    return Geolocator.distanceBetween(
          currentLatitude!,
          currentLongitude!,
          sellerLatitude,
          sellerLongitude,
        ) /
        1000; // Convert meters to kilometers
  }

  void _sortSellersByDistance() {
    filteredSellers.sort((a, b) {
      double distanceA = calculateDistance(a['latitude'], a['longitude']);
      double distanceB = calculateDistance(b['latitude'], b['longitude']);
      return distanceA.compareTo(distanceB);
    });
  }

  void applyToSeller(String sellerId) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Applied to seller $sellerId')));
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Image.network(imageUrl),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _searchSellers(String query) {
    setState(() {
      searchQuery = query;
      filteredSellers = sellers.where((seller) {
        final address = seller['address'].toString().toLowerCase();
        return address.contains(query.toLowerCase());
      }).toList();
      _sortSellersByDistance(); // Re-sort after filtering
    });
  }

  String formatCost(String value) {
    final number = double.tryParse(value.replaceAll(',', '')) ?? 0;
    return NumberFormat('#,##0.00').format(number); // Format with commas
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seller Requests'),
        backgroundColor: Colors.cyan,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false);
          },
        ),
      ),
      body: currentLatitude == null || currentLongitude == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by address',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _searchSellers,
                  ),
                ),
                Expanded(
                  child: filteredSellers.isEmpty
                      ? Center(child: Text('No sellers found'))
                      : ListView.builder(
                          itemCount: filteredSellers.length,
                          itemBuilder: (context, index) {
                            final seller = filteredSellers[index];
                            return Card(
                              margin: EdgeInsets.all(10),
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Broker',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    Text('Email: ${seller['userEmail']}',
                                        style: TextStyle(fontSize: 18)),
                                    SizedBox(height: 5),
                                    Text('Address: ${seller['address']}',
                                        style: TextStyle(fontSize: 16)),
                                    SizedBox(height: 10),
                                    Text(
                                      'Distance: ${calculateDistance(seller['latitude'], seller['longitude']).toStringAsFixed(2)} km',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 10),

                                    // Item Details Section
                                    Text('Item Details',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    if (seller['itemPhoto'] != null &&
                                        seller['itemPhoto'].isNotEmpty)
                                      Container(
                                        margin: EdgeInsets.only(bottom: 10),
                                        height: 150,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: seller['itemPhoto'].length,
                                          itemBuilder: (context, photoIndex) {
                                            return GestureDetector(
                                              onTap: () => _showImageDialog(
                                                  seller['itemPhoto']
                                                      [photoIndex]),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4.0),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Image.network(
                                                    seller['itemPhoto']
                                                        [photoIndex],
                                                    width: 100,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    Text('Item Name: ${seller['itemName']}',
                                        style: TextStyle(fontSize: 16)),
                                    SizedBox(height: 5),
                                    Text(
                                        'Item Cost: ${formatCost(seller['itemCost'])}  ${seller['currency']}',
                                        style: TextStyle(fontSize: 16)),
                                    SizedBox(height: 5),
                                    Text(
                                        'Payment Method: ${seller['paymentMethod']}',
                                        style: TextStyle(fontSize: 16)),
                                    SizedBox(height: 5),
                                    Text(
                                        'Description: ${seller['description']}',
                                        style: TextStyle(fontSize: 16)),
                                    SizedBox(height: 10),

                                    // Apply Button
                                    ElevatedButton(
                                      onPressed: () =>
                                          applyToSeller(seller['id']),
                                      child: Text('Apply'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
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
