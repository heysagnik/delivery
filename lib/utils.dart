import 'package:flutter/material.dart';
void showSnackBar(BuildContext context, String content) {

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Expanded(
        child: Text(
          content,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
  );
}



