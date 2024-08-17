import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'Components/custom_button.dart';
import 'Components/custom_textfield.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback showSignUpPage;
  const LoginPage({Key? key, required this.showSignUpPage}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // text controllers for fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // field for authenticating form state
  final _formField = GlobalKey<FormState>();
  final _formFieldPassword = GlobalKey<FormState>();

  // boolean to toggle password visibility
  late bool _passwordVisible;

  @override
  void initState() {
    _passwordVisible = false;
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Error message to user
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(message),
          icon: const Icon(Icons.error),
          iconColor: Colors.red,
        );
      },
    );
  }

  // sign in with email
  Future<void> signInWithEmail() async {
    if (!_formField.currentState!.validate()) {
      return;
    }
    if (!_formFieldPassword.currentState!.validate()) {
      return;
    }

    // show loading circle
    showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        });

    try {
      var userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      // var storage;
      // await storage.write(key: 'authToken', value: userCredential.credential);
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      // show error message
      if (e.code == 'wrong-password') {
        showErrorMessage("Incorrect password\nPlease try again");
      }
      if (e.code == 'user-not-found') {
        showErrorMessage("User not found\nPlease try again");
      }
      if (e.code == 'too-many-requests') {
        showErrorMessage(
            "You have attempted to login too many times\nPlease try again later");
      }
       if (e.code == 'user-disabled') {
    showErrorMessage(
        "This account has been disabled\nPlease contact support for assistance");
  }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Form(
        key: _formField,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Lottie.asset(
                    "lib/images/login_image.json",
                    width: 300,
                    height: 300,
                    repeat: false,
                  ),
                  const Center(
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // email field
                  CustomTextField(
                    validator: (email) {
                      return email != null && !EmailValidator.validate(email)
                          ? 'Enter a valid email'
                          : null;
                    },
                    controller: emailController,
                    hintText: "Email",
                    obscureText: false,
                    inputType: TextInputType.emailAddress,
                    icon: const Icon(
                      Icons.email,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // password field
                  Form(
                    key: _formFieldPassword,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextFormField(
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your password';
                          } else if (value.length < 8) {
                            return 'Minimum 8 characters required';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.text,
                        controller: passwordController,
                        obscureText: !_passwordVisible,
                        style: const TextStyle(fontSize: 20),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.password,
                            color: Colors.black,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            color: Colors.black,
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          hintText: "Password",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Sign in button
                  CustomButton(
                    onTap: signInWithEmail,
                    buttonName: "Sign in",
                    buttonColor: Colors.blue,
                    buttonText: '', // or any color you prefer

                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account? ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.showSignUpPage,
                        child: const Text(
                          'Sign Up now',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
