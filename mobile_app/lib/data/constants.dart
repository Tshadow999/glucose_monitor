import 'package:flutter/material.dart';

class CustomConstants {
  static const String themeModePrefKey = "themeMode";

  static const String glucoseUnitPrefKey = "glucoseUnit";

  static const String unitMmol = "mmol/L";
  static const String unitMg = "mg/dL";
}

class CustomTextStyles {
  static const TextStyle cardTitle = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    color: Colors.deepPurple,
    letterSpacing: 2.0,
  );

  static const TextStyle cardDescription = TextStyle(fontSize: 16.0);
}
