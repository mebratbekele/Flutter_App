import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/AuthGuard/AuthGuard.dart';
import 'package:flutter_application_1/AuthGuard/AuthWrapper.dart';
import 'package:flutter_application_1/Employee/EmployeeListScreen.dart';
import 'package:flutter_application_1/Employee/employe_registration.dart';
import 'package:flutter_application_1/Employee/employed.dart';
import 'package:flutter_application_1/Employee/employeeRequest.dart';
import 'package:flutter_application_1/Employee/employee_view.dart';
import 'package:flutter_application_1/Employer/employerListScreen.dart';
import 'package:flutter_application_1/Employer/employerRequest.dart';
import 'package:flutter_application_1/Home_page.dart';
import 'package:flutter_application_1/attachUserDetailInfo.dart';
import 'package:flutter_application_1/auth_page.dart';
import 'package:flutter_application_1/firebase_optrions.dart';
import 'package:flutter_application_1/job/post.dart';
import 'package:flutter_application_1/job/viewJob.dart';
import 'package:flutter_application_1/job/view_jobs_based_on_location.dart';
import 'package:flutter_application_1/registration.dart';
import 'package:flutter_application_1/userInfo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        "/addUsers": (context) => const AuthGuard(child: MyHomePage()),
        "/viewEmployee": (context) => AuthGuard(child: EmployeeList()),
        "/registerEmployee": (context) => AuthGuard(child: EmployeeForm()),
        "/postJob": (context) => AuthGuard(child: JobForm()),
        "/postJobRequest": (context) => JobFormRequest(
              email: '',
            ),
        "/postemployeRequest": (context) => JobSeekerRequestScreen(
              email: '',
            ),
        "/viewEmployeeList": (context) =>
            AuthGuard(child: EmployeeListScreen()),
        "/listOfJobs": (context) => JobList(),
        "/employerList": (context) => AuthGuard(child: EmployerDetailsPage()),
        "/viewEmployedList": (context) =>
            AuthGuard(child: EmployedListScreen()),
        "/listOfJobsBasedOnUser": (context) =>
            AuthGuard(child: JobListBasedOnLocation()),
        "/attachUserDetail": (context) => AuthGuard(child: UserDetailForm()),
        "/users": (context) => UserInfoPage(),
        "/login": (context) => const AuthPage(),
        "/home": (context) => const NavBar(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
