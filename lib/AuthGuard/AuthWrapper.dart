import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/auth_page.dart';
import 'package:flutter_application_1/home_page.dart'; // Make sure this import is correct

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // User is authenticated, show the NavBar
      return const NavBar();
    } else {
      // User is not authenticated, show the AuthPage
      return const AuthPage();
    }
  }
}
