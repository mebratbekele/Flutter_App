import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart'; // Import intl package for number formatting

class BuyerDetailsScreen extends StatefulWidget {
  final double currentLatitude;
  final double currentLongitude;

  BuyerDetailsScreen({
    required this.currentLatitude,
    required this.currentLongitude,
  });

  @override
  _BuyerDetailsScreenState createState() => _BuyerDetailsScreenState();
}

class _BuyerDetailsScreenState extends State<BuyerDetailsScreen> {
  final DatabaseReference databaseRef = FirebaseDatabase.instance.ref("buyers");
  List<Map<dynamic, dynamic>> buyers = [];
  List<Map<dynamic, dynamic>> filteredBuyers = [];
  String searchQuery = '';
  double? currentLatitude;
  double? currentLongitude;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    fetchBuyers();
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

  Future<void> fetchBuyers() async {
    databaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          buyers = data.entries
              .map((e) => e.value as Map<dynamic, dynamic>)
              .where((seller) =>
                  seller['status'] == 0) // Filter sellers with status = 0
              .toList();
          filteredBuyers = buyers; // Initialize filtered sellers
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
    filteredBuyers.sort((a, b) {
      double distanceA = calculateDistance(a['latitude'], a['longitude']);
      double distanceB = calculateDistance(b['latitude'], b['longitude']);
      return distanceA.compareTo(distanceB);
    });
  }

  void applyToSeller(String sellerId) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Applied to Buyer $sellerId')));
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

  void _searchBuyers(String query) {
    setState(() {
      searchQuery = query;
      filteredBuyers = buyers.where((seller) {
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
        title: Text('Buyer Requests'),
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
                    onChanged: _searchBuyers,
                  ),
                ),
                Expanded(
                  child: filteredBuyers.isEmpty
                      ? Center(child: Text('No Buyers found'))
                      : ListView.builder(
                          itemCount: filteredBuyers.length,
                          itemBuilder: (context, index) {
                            final buyer = filteredBuyers[index];
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
                                    Text('Email: ${buyer['userEmail']}',
                                        style: TextStyle(fontSize: 18)),
                                    SizedBox(height: 5),
                                    Text('Address: ${buyer['address']}',
                                        style: TextStyle(fontSize: 16)),
                                    SizedBox(height: 10),
                                    Text(
                                      'Distance: ${calculateDistance(buyer['latitude'], buyer['longitude']).toStringAsFixed(2)} km',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 10),

                                    // Item Details Section
                                    Text('Item Details',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    if (buyer['itemPhoto'] != null &&
                                        buyer['itemPhoto'].isNotEmpty)
                                      Container(
                                        margin: EdgeInsets.only(bottom: 10),
                                        height: 150,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: buyer['itemPhoto'].length,
                                          itemBuilder: (context, photoIndex) {
                                            return GestureDetector(
                                              onTap: () => _showImageDialog(
                                                  buyer['itemPhoto']
                                                      [photoIndex]),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4.0),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Image.network(
                                                    buyer['itemPhoto']
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
                                    Text('Item Name: ${buyer['itemName']}',
                                        style: TextStyle(fontSize: 16)),
                                    SizedBox(height: 5),
                                    Text(
                                        'Item Cost: ${formatCost(buyer['itemCost'])}  ${buyer['currency']}',
                                        style: TextStyle(fontSize: 16)),
                                    SizedBox(height: 5),

                                    Text(
                                        'Payment Method: ${buyer['paymentMethod']}',
                                        style: TextStyle(fontSize: 16)),
                                    SizedBox(height: 5),
                                    Text('Description: ${buyer['description']}',
                                        style: TextStyle(fontSize: 16)),
                                    SizedBox(height: 10),

                                    // Apply Button
                                    ElevatedButton(
                                      onPressed: () =>
                                          applyToSeller(buyer['id']),
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
