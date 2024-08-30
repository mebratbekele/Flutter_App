import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/auth_page.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // User is authenticated, show the child widget
      return child;
    } else {
      // User is not authenticated, redirect to the AuthPage
      return const AuthPage();
    }
  }
}
