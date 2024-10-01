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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formField = GlobalKey<FormState>();
  final _formFieldPassword = GlobalKey<FormState>();
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

  Future<void> signInWithEmail() async {
    if (!_formField.currentState!.validate()) return;
    if (!_formFieldPassword.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      if (e.code == 'wrong-password') {
        showErrorMessage("Incorrect password\nPlease try again");
      } else if (e.code == 'user-not-found') {
        showErrorMessage("User not found\nPlease try again");
      } else if (e.code == 'too-many-requests') {
        showErrorMessage("Too many attempts\nPlease try again later");
      } else if (e.code == 'user-disabled') {
        showErrorMessage("This account is disabled\nContact support");
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
                    icon: const Icon(Icons.email, color: Colors.black),
                  ),
                  const SizedBox(height: 20),
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
                          prefixIcon:
                              const Icon(Icons.password, color: Colors.black),
                          suffixIcon: IconButton(
                            icon: Icon(_passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            color: Colors.black,
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                          hintText: "Password",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  CustomButton(
                    onTap: signInWithEmail,
                    buttonName: "Sign in",
                    buttonColor: Colors.blue,
                    buttonText: 'Sign in',
                  ),
                  const SizedBox(height: 30),
                  const Divider(color: Colors.white),

                  // Below Sign In Button
                  _buildFooterLink(
                    context,
                    'Don\'t have an account? ',
                    'Sign Up now',
                    widget.showSignUpPage,
                    Colors.redAccent,
                  ),
                  const SizedBox(height: 20),
                  _buildFooterLink(
                    context,
                    'You want to find a job? ',
                    'Please click here now',
                    () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/listOfJobs', (route) => false);
                    },
                    Colors.redAccent,


                    
                  ),
                  const SizedBox(height: 20),
                  _buildFooterLink(
                    context,
                    'You want to Visit Brokers? ',
                    'Please click here now',
                    () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/users', (route) => false);
                    },
                    Colors.orangeAccent,
                  ),
                  const SizedBox(height: 20),
                  _buildFooterLink(
                    context,
                    'You want to Visit selling items? ',
                    'Please click here now',
                    () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/selling', (route) => false);
                    },
                    Colors.blue,
                  ),
                  const SizedBox(height: 20),
                  _buildFooterLink(
                    context,
                    'You want to Visit buying items? ',
                    'Please click here now',
                    () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/buying', (route) => false);
                    },
                    Colors.cyan,
                  ),
                  const Divider(color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink(BuildContext context, String message, String linkText,
      VoidCallback onTap, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            linkText,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
