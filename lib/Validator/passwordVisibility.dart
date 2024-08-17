import 'package:flutter/material.dart';
import 'package:flutter_application_1/Validator/validator.dart';

class PasswordVisibility extends StatefulWidget {
  const PasswordVisibility({super.key});

  @override
  State<PasswordVisibility> createState() => _PasswordVisibilityState();
}

class _PasswordVisibilityState extends State<PasswordVisibility> {
  bool _isVisible = false;
  final TextEditingController _passwordController = TextEditingController();
  getPassword() {
    return _passwordController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: TextFormField(
        controller: _passwordController,
        keyboardType: TextInputType.visiblePassword,
        style: TextStyle(color: Colors.white),
        obscureText: !_isVisible,
        decoration: InputDecoration(
          labelText: 'Password',
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          prefixIcon: Icon(Icons.password),
          prefixIconColor: Colors.white,
          labelStyle: TextStyle(color: Colors.white),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.blue),
            borderRadius: BorderRadius.circular(10),
          ),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _isVisible = !_isVisible;
              });
            },
            icon: Icon(
              _isVisible ? Icons.visibility_off : Icons.visibility,
            ),
          ),
        ),
        // validator: (value) {
        //   if (value == null || value.isEmpty) {
        //     return 'Please enter your Password';
        //   }
        //   return null;
        // },
        validator: (val) {
          if (!val!.isValidPassword) {
            return 'Enter valid password';
          }
        },

        maxLength: 40,
      ),
    );
  }
}
