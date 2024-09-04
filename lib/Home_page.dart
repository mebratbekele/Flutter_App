import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class NavBar extends StatefulWidget {
  const NavBar({Key? key}) : super(key: key);

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  String _profilePictureUrl = '';
  String _username = 'Guest@gmail.com';
  String _fullName = '';
  String _phone = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final email = user.email ?? '';
      final databaseRef = FirebaseDatabase.instance.ref().child('userDetails');
      final snapshot =
          await databaseRef.orderByChild('email').equalTo(email).once();

      if (snapshot.snapshot.children.isNotEmpty) {
        final userData =
            snapshot.snapshot.children.first.value as Map<dynamic, dynamic>;
        setState(() {
          _username = userData['email'] ?? 'Guest@gmail.com';
          _fullName = userData['fullName'] ?? '';
          _phone = userData['phone'] ?? '';
          _role = userData['role'] ?? '';
          _profilePictureUrl = userData['profilePictureUrl'] ?? '';
        });
      }
    }
  }

  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      appBar: AppBar(
        title: Text(
          'BROKER APPLICATION',
          style: const TextStyle(
            color: Colors.white,
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
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context);
              }
              // Add functionality for 'change_password' here if needed
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.black),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'change_password',
                  child: Row(
                    children: [
                      Icon(Icons.password, color: Colors.black),
                      SizedBox(width: 8),
                      Text('Change Password'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildDrawerHeader(),
              const Divider(color: Colors.cyan),

              _buildDrawerItem(
                  context, Icons.edit, 'Your Detail Info', '/attachUserDetail'),
              _buildDrawerItem(
                  context, Icons.person, 'View Jobs', '/listOfJobsBasedOnUser'),
              _buildDrawerItem(
                  context, Icons.share, 'Image', null), // No action
              _buildDrawerItem(
                  context, Icons.account_circle, 'Users', '/users'),
              // const Divider(color: Colors.white),
              _buildDrawerItem(
                  context, Icons.settings, 'Post Jobs', '/postJob'),
              // _buildDrawerItem(context, Icons.description, 'Attach Your Detail',
              //     '/attachUserDetail'),
              const Divider(color: Colors.cyan),
              _buildDrawerItem(context, Icons.exit_to_app, 'Logout', null,
                  logout: true),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStyledButton(
                      context,
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/employerList', (route) => false),
                      icon: Icons.manage_accounts_sharp,
                      gradientColors: [Colors.blue, Colors.deepOrange],
                      label: 'Employers',
                    ),
                    const SizedBox(height: 15),
                    _buildStyledButton(
                      context,
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/viewEmployeeList', (route) => false),
                      icon: Icons.manage_accounts_rounded,
                      gradientColors: [Colors.blue, Colors.orange],
                      label: 'Job Seekers',
                    ),
                    const SizedBox(height: 15),
                    _buildStyledButton(
                      context,
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/viewEmployedList', (route) => false),
                      icon: Icons.manage_accounts,
                      gradientColors: [Colors.orange, Colors.indigo],
                      label: 'Employee',
                    ),
                    const SizedBox(height: 15),
                    _buildStyledButton(
                      context,
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/listOfJobsBasedOnUser', (route) => false),
                      icon: Icons.manage_history_rounded,
                      gradientColors: [Colors.deepOrangeAccent, Colors.blue],
                      label: 'Jobs',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: _profilePictureUrl.isNotEmpty
                  ? Image.network(
                      _profilePictureUrl,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                    )
                  : Icon(Icons.person, size: 70, color: Colors.grey[800]),
            ),
          ),
          SizedBox(height: 10),
          Text(
            _fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 5),
          Text(
            '$_username\n$_phone\nRole: $_role',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, String? route,
      {bool logout = false}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        if (logout) {
          _logout(context);
        } else if (route != null) {
          Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
        }
      },
    );
  }

  Widget _buildStyledButton(
    BuildContext context, {
    required VoidCallback onPressed,
    required IconData icon,
    required List<Color> gradientColors,
    required String label,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
        backgroundColor: Colors.transparent, // Transparent to apply gradient
      ).copyWith(
        shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.3)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 25,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
