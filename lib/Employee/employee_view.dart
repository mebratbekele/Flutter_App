import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Employee/employe_registration.dart';

class EmployeeList extends StatefulWidget {
  @override
  _EmployeeListState createState() => _EmployeeListState();
}

class _EmployeeListState extends State<EmployeeList> {
  final DatabaseReference _employeeRef =
      FirebaseDatabase.instance.ref().child('employees');
  late Stream<DatabaseEvent> _employeeStream;

  @override
  void initState() {
    super.initState();
    _employeeStream = _employeeRef.onValue; // Correct type is DatabaseEvent
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee List'),
        backgroundColor: Colors.blue, // You can choose a different color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          },
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _employeeStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
            return Center(child: Text('No employees found.'));
          }

          final Map<dynamic, dynamic> employees =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employeeId = employees.keys.elementAt(index);
              final employee = employees[employeeId];

              return ListTile(
                title: Text(employee['full_name']),
                subtitle: Text(
                    '${employee['age']} years old\nGender: ${employee['gender']}\nPhone: ${employee['phone']}'),
                leading: employee['photo_url'] != null
                    ? Image.network(employee['photo_url'],
                        width: 50, height: 50, fit: BoxFit.cover)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  EmployeeForm(employeeId: employeeId)),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _confirmDelete(employeeId);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EmployeeForm()),
          );
        },
        label: Text('New Employee'),
        icon: Icon(Icons.add),
        backgroundColor: Colors.blue, // You can choose a different color
      ),
    );
  }

  Future<void> _confirmDelete(String employeeId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this employee?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      _deleteEmployee(employeeId);
    }
  }

  Future<void> _deleteEmployee(String employeeId) async {
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('employees')
          .child(employeeId)
          .remove();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Employee deleted successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting employee')));
    }
  }
}
