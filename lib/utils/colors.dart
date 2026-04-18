// colors.dart
// This file stores all our app colors in one place
// So if we want to change red color, we change it here ONCE
// and it updates everywhere in the app automatically

import 'package:flutter/material.dart';

class AppColors {
  // Main red color - used for buttons, AppBar, urgent things
  static const Color primary = Color(0xFFD32F2F);

  // White - used for text on red backgrounds, card backgrounds
  static const Color white = Color(0xFFFFFFFF);

  // Light grey - used as screen background color
  static const Color background = Color(0xFFF5F5F5);

  // Dark grey - used for normal text
  static const Color textDark = Color(0xFF212121);

  // Green - used for "Available" status indicator
  static const Color available = Color(0xFF4CAF50);

  // Light red - used for input field borders and hints
  static const Color lightRed = Color(0xFFFFCDD2);
}