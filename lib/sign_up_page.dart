import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Components/custom_button.dart';
import 'package:flutter_application_1/Components/custom_textfield.dart';
import 'package:lottie/lottie.dart';

import 'package:slider_captcha/slider_captcha.dart';

class SignUpPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const SignUpPage({Key? key, required this.showLoginPage}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // text controllers for fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final controller = SliderController();

  // field for authenticating form state
  final _formField = GlobalKey<FormState>();

  // boolean to toggle password visibility
  late bool _passwordVisible;

  // variable to hold strength of password
  // 0: No password/Too short
  // 1/4: Weak
  // 2/4: Fair
  // 3/4: Good
  // 1: Strong
  double _strength = 0;
  bool isLength = false;
  bool isUpperCase = false;
  bool isNumber = false;
  bool isSpecial = false;

  bool isCaptchaVerified = false;

  // regular expressions for numbers, letters and special characters
  RegExp numReg = RegExp(r".*[0-9].*");
  RegExp uppercaseReg = RegExp(r".*[A-Z].*");
  RegExp specialCharactersReg = RegExp(r'.*[!@#$%^&*(),.?":{}|<>].*');

  late String _password;

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

  // method to check password
  void _checkPassword(String password) {
    _password = password.trim();
    var i = 0;
    if (_password.length >= 8) {
      setState(() {
        isLength = true;
      });
      i++;
    } else {
      setState(() {
        isLength = false;
      });
    }

    if (uppercaseReg.hasMatch(_password)) {
      setState(() {
        isUpperCase = true;
      });
      i++;
    } else {
      setState(() {
        isUpperCase = false;
      });
    }

    if (numReg.hasMatch(_password)) {
      setState(() {
        isNumber = true;
      });
      i++;
    } else {
      isNumber = false;
    }

    if (specialCharactersReg.hasMatch(_password)) {
      setState(() {
        isSpecial = true;
      });
      i++;
    } else {
      setState(() {
        isSpecial = false;
      });
    }

    // setting strength of progress bar
    if (i == 0) {
      setState(() {
        _strength = 0;
      });
    }
    if (i == 1) {
      setState(() {
        _strength = 1 / 4;
      });
    }
    if (i == 2) {
      setState(() {
        _strength = 2 / 4;
      });
    }
    if (i == 3) {
      setState(() {
        _strength = 3 / 4;
      });
    }
    if (i == 4) {
      setState(() {
        _strength = 1;
      });
    }
  }

  // method to register user
  Future<void> signUpWithEmail() async {
    if (!_formField.currentState!.validate()) {
      return;
    }

    // show loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      print("hello 1");
      var userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      print("hello 2 ");
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      // show error message
      if (e.code == 'email-already-in-use') {
        showErrorMessage('An account already exists\nfor that email');
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // when page is loaded visibility of password is set to false
    _passwordVisible = false;
    super.initState();
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
                    "lib/images/signUp_image.json",
                    width: 300,
                    height: 300,
                    repeat: false,
                  ),
                  const Center(
                    child: Text(
                      "Sign Up",
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: TextField(
                      onChanged: (value) => _checkPassword(value),
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
                  const SizedBox(height: 20),
                  // progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: LinearProgressIndicator(
                      value: _strength,
                      minHeight: 15,
                      // colour is changed depending on the strength of the password
                      color: _strength == 1 / 4
                          ? Colors.red
                          : _strength == 2 / 4
                              ? Colors.yellow
                              : _strength == 3 / 4
                                  ? Colors.blue
                                  : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // strength validation message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Password must include:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text.rich(
                            TextSpan(
                              children: [
                                WidgetSpan(
                                  child: Icon(
                                    Icons.done_rounded,
                                    color: isLength ? Colors.green : Colors.red,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Minimum 8 characters',
                                  style: TextStyle(
                                    color: isLength ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                WidgetSpan(
                                  child: Icon(
                                    Icons.done_rounded,
                                    color:
                                        isUpperCase ? Colors.green : Colors.red,
                                  ),
                                ),
                                TextSpan(
                                  text: 'At least one uppercase character',
                                  style: TextStyle(
                                    color:
                                        isUpperCase ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                WidgetSpan(
                                  child: Icon(
                                    Icons.done_rounded,
                                    color: isNumber ? Colors.green : Colors.red,
                                  ),
                                ),
                                TextSpan(
                                  text: 'At least one number',
                                  style: TextStyle(
                                    color: isNumber ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                WidgetSpan(
                                  child: Icon(
                                    Icons.done_rounded,
                                    color:
                                        isSpecial ? Colors.green : Colors.red,
                                  ),
                                ),
                                TextSpan(
                                  text: 'At least one special character',
                                  style: TextStyle(
                                    color:
                                        isSpecial ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // slider captcha
                  Container(
                    // if captcha is not verified captcha slider is shown
                    child: !isCaptchaVerified
                        ? SliderCaptcha(
                            titleStyle: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            colorCaptChar: Colors.white,
                            colorBar: Colors.grey.shade200,
                            controller: controller,
                            image: Image.asset(
                              'lib/images/car.png',
                              fit: BoxFit.fitWidth,
                            ),
                            onConfirm: (bool value) async {
                              if (value == true) {
                                setState(() {
                                  isCaptchaVerified = true;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text("Captcha verified"),
                                  ));
                                });
                              }
                            },
                          )
                        // if captcha is verified empty container is shown
                        : Container(),
                  ),
                  const SizedBox(height: 25),
                  // sign up button
                  CustomButton(
                    // button only enabled if conditions are met and captcha is verified
                    onTap: () => signUpWithEmail(),
                    buttonName: "Sign Up",
                     buttonColor: Colors.blue,
                    buttonText: '', // or any color you prefer
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.showLoginPage,
                        child: const Text(
                          'Login now',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
