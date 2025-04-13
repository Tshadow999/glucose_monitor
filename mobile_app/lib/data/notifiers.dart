import 'package:sugar_daddy/data/auth_service.dart';
import 'package:flutter/material.dart';

ValueNotifier<int> selectedPageNotifier = ValueNotifier(0);
ValueNotifier<bool> darkModeNotifier = ValueNotifier(true);

/// True for mg/dL false for mmol/L
///
/// glucoseUnitNotifier.value ? CustomConstants.unitMg : CustomConstants.unitMmol
ValueNotifier<bool> glucoseUnitNotifier = ValueNotifier(true);

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());
