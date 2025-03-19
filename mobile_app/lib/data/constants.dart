import 'package:flutter/material.dart';

class CustomConstants {
  static const String themeModePrefKey = "themeMode";

  static const String glucoseUnitPrefKey = "glucoseUnit";

  static const String unitMmol = "mmol/L";
  static const String unitMg = "mg/dL";
}

class CustomTextStyles {
  CustomTextStyles(BuildContext context) {
    context = context;
  }

  static BuildContext? context;
  static TextStyle cardTitle(BuildContext context) {
    return TextStyle(
      fontSize: 24.0,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.primary,
      letterSpacing: 2.0,
    );
  }

  static const TextStyle settingsTitle = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 3,
  );

  static const TextStyle cardDescription = TextStyle(fontSize: 16.0);
}
