import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List<User> _userList = [];

  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    getAllUserDetails();
  }

  Future<void> getAllUserDetails() async {
    // Fetch all users from Firebase Authentication
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        setState(() {
          _userList = [
            currentUser
          ]; // For demonstration, showing only the current user
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load user details');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(User user) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Are you sure you want to delete this user?',
            style: TextStyle(color: Colors.teal, fontSize: 20),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                try {
                  // Log out the user
                  await user.delete();
                  Navigator.pop(context);
                  getAllUserDetails();
                  _showSuccessSnackBar('User deleted successfully');
                } catch (e) {
                  _showErrorSnackBar('Failed to delete user');
                }
              },
              child: const Text('Delete'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.teal,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
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
        title: const Text("Manage Firebase Users"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ),
      body: ListView.builder(
        itemCount: _userList.length,
        itemBuilder: (context, index) {
          var user = _userList[index];
          return Card(
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewUser(user: user),
                  ),
                );
              },
              leading: const Icon(Icons.person),
              title: Text(user.email ?? ''),
              subtitle: Text(user.uid ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditUser(user: user),
                        ),
                      ).then((data) {
                        if (data != null) {
                          getAllUserDetails();
                          _showSuccessSnackBar('User updated successfully');
                        }
                      });
                    },
                    icon: const Icon(Icons.edit, color: Colors.teal),
                  ),
                  IconButton(
                    onPressed: () {
                      _showDeleteConfirmationDialog(user);
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddUser()),
          ).then((data) {
            if (data != null) {
              getAllUserDetails();
              _showSuccessSnackBar('User added successfully');
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Placeholder widgets for ViewUser, EditUser, and AddUser
class ViewUser extends StatelessWidget {
  final User user;
  const ViewUser({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('View User')),
      body: Center(child: Text('User Email: ${user.email}')),
    );
  }
}

class EditUser extends StatelessWidget {
  final User user;
  const EditUser({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit User')),
      body: Center(child: Text('Edit user details here')),
    );
  }
}

class AddUser extends StatelessWidget {
  const AddUser({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add User')),
      body: Center(child: Text('Add new user here')),
    );
  }
}
