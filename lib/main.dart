import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Employee/employe_registration.dart';
import 'package:flutter_application_1/Home_page.dart';
import 'package:flutter_application_1/auth_page.dart';
import 'package:flutter_application_1/firebase_optrions.dart';
import 'package:flutter_application_1/registration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        "/addUsers": (context) => MyHomePage(),
        "/registerEmployee": (context) => EmployeeForm(),
        "/login": (context) => AuthPage(),
        "/home": (context) => NavBar(),
      },
      debugShowCheckedModeBanner: false, // Hides the debug banner
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final Widget? child;

  const AuthWrapper({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if the user is authenticated
    if (FirebaseAuth.instance.currentUser != null) {
      // If authenticated, show the provided child widget
      return const NavBar();
    } else {
      // If not authenticated, show the AuthPage
      return const AuthPage();
    }
  }
}
