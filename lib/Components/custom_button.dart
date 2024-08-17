import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    Key? key,
    required this.onTap,
    required this.buttonName, required Color buttonColor, required String buttonText,
  }) : super(key: key);

  final Function()? onTap;
  final String buttonName;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        // disabledBackgroundColor: Colors.grey[500],
        backgroundColor: Colors.grey[200],
        // backgroundColor: Colors.white,
        minimumSize: const Size(170, 50),
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
      onPressed: onTap,
      child: Text(
        buttonName,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
