import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  const NavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retrieve the current user's email from Firebase Authentication
    String? username;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      username = user.email;
    }
    if (username == null || username.isEmpty) {
      username = 'Guest@gmail.com';
    }

    // Function to handle logout
    void logout() {
      FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }

    // Function to handle navigation to add user page
    void addUser() {
      Navigator.pushNamedAndRemoveUntil(context, '/addUsers', (route) => false);
    }

    // Function to handle navigation to view accounts page
    void viewAccounts() {
      Navigator.pushNamedAndRemoveUntil(
          context, '/viewAccounts', (route) => false);
    }

    // Function to handle navigation to employee registration page
    void employeeRegistration() {
      Navigator.pushNamedAndRemoveUntil(
          context, '/registerEmployee', (route) => false);
    }

    // Function to handle navigation to forgot password page
    void viewUser() {
      Navigator.pushNamedAndRemoveUntil(
          context, '/forgotPassword', (route) => false);
    }

    // Function to handle navigation to registration page
    void register() {
      Navigator.pushNamedAndRemoveUntil(context, '/register', (route) => false);
    }

    return Scaffold(
      backgroundColor: Color.fromARGB(248, 14, 212, 212), // Background color
      appBar: AppBar(
        title: Text(
          'ABCD PLC System',
          style: TextStyle(
            color: Color.fromARGB(255, 28, 4, 248), // Custom orange color
            fontSize: 18, // Optional: set font size
            fontWeight: FontWeight.bold, // Optional: set font weight
          ),
        ),
        backgroundColor: Color.fromARGB(248, 185, 238, 242),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'logout':
                  logout();
                  break;
                case 'change_password':
                  // Add your change password functionality here
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.black),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
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
          color: Colors.blue[900],
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                accountEmail: Text(
                  username,
                  style: TextStyle(
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
                  color: Colors.blue[900],
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(
                      'https://oflutter.com/wp-content/uploads/2021/02/profile-bg3.jpg',
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.favorite, color: Colors.white),
                title: Text('Employee', style: TextStyle(color: Colors.white)),
                onTap: employeeRegistration,
              ),
              ListTile(
                leading: Icon(Icons.person, color: Colors.white),
                title: Text('Add User', style: TextStyle(color: Colors.white)),
                onTap: addUser,
              ),
              ListTile(
                leading: Icon(Icons.share, color: Colors.white),
                title: Text('Image', style: TextStyle(color: Colors.white)),
                onTap: () => null,
              ),
              ListTile(
                leading: Icon(Icons.account_circle, color: Colors.white),
                title: Text('Account', style: TextStyle(color: Colors.white)),
                onTap: viewAccounts,
                trailing: ClipOval(
                  child: Container(
                    color: Colors.red,
                    width: 20,
                    height: 20,
                    child: Center(
                      child: Text(
                        '8',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Divider(color: Colors.white),
              ListTile(
                leading: Icon(Icons.settings, color: Colors.white),
                title: Text('Roles', style: TextStyle(color: Colors.white)),
                onTap: viewUser,
              ),
              ListTile(
                leading: Icon(Icons.description, color: Colors.white),
                title: Text('User Registration',
                    style: TextStyle(color: Colors.white)),
                onTap: register,
              ),
              Divider(color: Colors.white),
              ListTile(
                title: Text('Logout', style: TextStyle(color: Colors.white)),
                leading: Icon(Icons.exit_to_app, color: Colors.white),
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                },
              ),
            ],
          ),
        ),
      ),
 body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Add Button with Icon and Text
            ElevatedButton.icon(
              onPressed: () {
                // Handle add button press
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.orange, // Text color
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50), // Circular shape
                ),
                minimumSize: Size(150, 150), // Size of the button
              ),
              icon: Icon(Icons.add, size: 40), // Icon size
              label: Text(
                'Add Employee',
                style: TextStyle(fontSize: 20),
              ),
            ),
            SizedBox(height: 15), // Space between buttons
            // View Button with Icon and Text
            ElevatedButton.icon(
              onPressed: () {
                // Handle view button press
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50), // Circular shape
                ),
                minimumSize: Size(150, 150), // Size of the button
              ),
              icon: Icon(Icons.remove_red_eye, size: 40), // Icon size
              label: Text(
                'View Employee',
                style: TextStyle(fontSize: 20),
              ),
            ),
            SizedBox(height: 15),
            // Edit Button with Icon and Text
            ElevatedButton.icon(
              onPressed: () {
                // Handle edit button press
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green, // Text color
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50), // Circular shape
                ),
                minimumSize: Size(150, 150), // Size of the button
              ),
              icon: Icon(Icons.edit, size: 40), // Icon size
              label: Text(
                'Edit Employee',
                style: TextStyle(fontSize: 20),
              ),
            ),
            SizedBox(height: 15),
            // Delete Button with Icon and Text
            ElevatedButton.icon(
              onPressed: () {
                // Handle delete button press
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.red, // Text color
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50), // Circular shape
                ),
                minimumSize: Size(150, 150), // Size of the button
              ),
              icon: Icon(Icons.delete, size: 40), // Icon size
              label: Text(
                'Delete Employee',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
     );
  }
}
