import 'package:flutter/material.dart';

class SimpleTestWidget extends StatelessWidget {
  const SimpleTestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.yellow, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🔥 ENHANCED FEATURES ACTIVE! 🔥',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}