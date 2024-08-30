import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  const NavBar({Key? key}) : super(key: key);

  // Function to handle logout
  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve the current user's email from Firebase Authentication
    final User? user = FirebaseAuth.instance.currentUser;
    final String username = user?.email ?? 'Guest@gmail.com';

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
              _buildDrawerHeader(username),
              _buildDrawerItem(
                  context, Icons.favorite, 'Employee', '/viewEmployee'),
              _buildDrawerItem(
                  context, Icons.person, 'View Jobs', '/listOfJobsBasedOnUser'),
              _buildDrawerItem(
                  context, Icons.share, 'Image', null), // No action
              _buildDrawerItem(
                  context, Icons.account_circle, 'Account', '/viewAccounts'),
              const Divider(color: Colors.white),
              _buildDrawerItem(
                  context, Icons.settings, 'Post Jobs', '/postJob'),
              _buildDrawerItem(
                  context, Icons.description, 'User Registration', '/register'),
              const Divider(color: Colors.white),
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

  Widget _buildDrawerHeader(String username) {
    return UserAccountsDrawerHeader(
      accountName: const Text(
        'Welcome',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      accountEmail: Text(
        username,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.asset(
            'assets/user.jfif',
            fit: BoxFit.cover,
            width: 90,
            height: 90,
          ),
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        image: DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(
              'https://oflutter.com/wp-content/uploads/2021/02/profile-bg3.jpg'),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, String? route,
      {bool logout = false}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      onTap: () {
        if (logout) {
          _logout(context);
        } else if (route != null) {
          Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
        }
      },
      trailing: logout
          ? null
          : ClipOval(
              child: Container(
                color: Colors.grey,
                width: 20,
                height: 20,
                child: Center(
                  child: Text(
                    '',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
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
        backgroundColor: Colors.white30, // Transparent to apply gradient
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
