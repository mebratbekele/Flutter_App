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
import 'package:flutter_application_1/buyer/view.dart';
import 'package:flutter_application_1/firebase_optrions.dart';
import 'package:flutter_application_1/job/link_jobseeker_with_employer.dart';
import 'package:flutter_application_1/job/post.dart';
import 'package:flutter_application_1/job/viewJob.dart';
import 'package:flutter_application_1/job/view_jobs_based_on_location.dart';
import 'package:flutter_application_1/link_seller_buyer.dart';
import 'package:flutter_application_1/registration.dart';
import 'package:flutter_application_1/seller/manage_seller_&_buyer_after_link.dart';
import 'package:flutter_application_1/seller/view.dart';
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
        "/linkJobseekerWithEmployer": (context) =>
            AuthGuard(child: JobseekerLinkWithEmployerScreen()),
        "/seller_buyer_after_link": (context) =>
            AuthGuard(child: SellerBuyerAfterLinkDisplayScreen()),
        "/linkSellerWithBuyer": (context) =>
            AuthGuard(child: SellerBuyerLinkScreen()),
        "/attachUserDetail": (context) => AuthGuard(child: UserDetailForm()),
        "/users": (context) => UserInfoPage(),
        "/selling": (context) => SellerDetailsScreen(),
        "/buying": (context) => BuyerDetailsScreen(
              currentLatitude: 0.0, // Placeholder, will not be used
              currentLongitude: 0.0, // Placeholder, will not be used
            ),
        "/login": (context) => const AuthPage(),
        "/home": (context) => const NavBar(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
