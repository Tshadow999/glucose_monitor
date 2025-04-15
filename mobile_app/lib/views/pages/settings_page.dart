import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sugar_daddy/data/constants.dart';
import 'package:sugar_daddy/data/local_storage.dart';
import 'package:sugar_daddy/data/ml_model_service.dart';
import 'package:sugar_daddy/data/notifiers.dart';
import 'package:sugar_daddy/views/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController controller = TextEditingController();

  double sliderValue = 0.0;
  String selectedUnit = CustomConstants.unitMmol;
  double get unitMultiplier =>
      selectedUnit == CustomConstants.unitMmol ? 1.0 : 18.0;

  // mmol/L default
  double minGlucose = 4.0;
  double maxGlucose = 8.0;

  bool isDarkMode = true;

  @override
  void initState() {
    super.initState();

    loadPrefs();
  }

  Future<void> loadPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool unit =
        prefs.getBool(CustomConstants.glucoseUnitPrefKey) ?? false;
    setState(() {
      selectedUnit = unit ? CustomConstants.unitMg : CustomConstants.unitMmol;
      isDarkMode = prefs.getBool(CustomConstants.themeModePrefKey) ?? false;

      minGlucose = prefs.getDouble('min_glucose') ?? 4.0;
      maxGlucose = prefs.getDouble('max_glucose') ?? 8.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ...listTitle("Customization"),
            SwitchListTile(
              title: Text("Dark Mode", style: CustomTextStyles.settingsItem),
              value: isDarkMode,
              onChanged: (value) async {
                setState(() {
                  isDarkMode = value;
                  darkModeNotifier.value = value;
                });

                final SharedPreferences prefs =
                    await SharedPreferences.getInstance();
                await prefs.setBool(
                  CustomConstants.themeModePrefKey,
                  darkModeNotifier.value,
                );
              },
            ),
            SizedBox(height: 16),
            glucoseUnitToggle(),
            SizedBox(height: 16),
            glucoseThresholdSliders(),
            SizedBox(height: 16),
            ...listTitle("Profile"),
            ListTile(
              title: Text("Logout", style: CustomTextStyles.settingsItem),
              onTap: () {
                logout(context);
              },
            ),
            ListTile(
              title: Text(
                "Update Password",
                style: CustomTextStyles.settingsItem,
              ),
              onTap: () => updatePassword(context),
            ),
            ListTile(
              title: Text(
                "Delete Account",
                style: CustomTextStyles.settingsItem.apply(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () => deleteAccount(context),
            ),
            SizedBox(height: 160),
            ...listTitle("Debugging"),
            TextButton(
              onPressed: () async {
                try {
                  List<double> predictions = await runModelFromCsv();

                  if (!context.mounted || predictions.isEmpty) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('AI is finished')));

                  GlucoseReadingService().addReadings(predictions);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: Text("Do AI"),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                DateTime now = DateTime.now();
                final random = Random();
                for (int i = 15; i > 0; i--) {
                  double reading;
                  if (i > 5) {
                    reading = 110.0 + random.nextInt(5);
                  } else if (i > 10) {
                    reading = 110.0 + random.nextInt(10);
                  } else {
                    reading = 120.0 + random.nextInt(10);
                  }

                  // For debugging
                  GlucoseReadingService().addReading(
                    reading,
                    now.subtract(Duration(minutes: 15 * i)),
                  );
                  /*
                  NotificationService().show(
                    id: 3,
                    title: "Warning high blood sugar detected",
                    body:
                        "Your blood sugar is $reading mg/dL, consider taking action!",
                  );
                  */
                }
              },
              child: Text("Add data"),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await GlucoseReadingService().deleteAll();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Local data is deleted")),
                );
              },
              child: Text("Delete local Data"),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> listTitle(String title) {
    return [
      Divider(),
      Text(title, style: CustomTextStyles.settingsTitle),
      Divider(),
    ];
  }

  Widget glucoseThresholdSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Glucose Thresholds",
            style: CustomTextStyles.settingsItem,
          ),
        ),
        SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Min: ${(minGlucose * unitMultiplier).toStringAsFixed(1)} $selectedUnit",
                  ),
                  Text(
                    "Max: ${(maxGlucose * unitMultiplier).toStringAsFixed(1)} $selectedUnit",
                  ),
                ],
              ),
              RangeSlider(
                values: RangeValues(minGlucose, maxGlucose),
                min: 2.0,
                max: 10.0,
                divisions: 130,
                labels: null,
                /* optional:
                angeLabels(
                  (minGlucose * unitMultiplier).toStringAsFixed(1),
                  (maxGlucose * unitMultiplier).toStringAsFixed(1),
                ),
                */
                onChanged: (RangeValues values) {
                  setState(() {
                    minGlucose = values.start;
                    maxGlucose = values.end;
                  });
                },
                onChangeEnd: (RangeValues values) {
                  saveGlucoseThresholds();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget glucoseUnitToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Glucose Unit", style: CustomTextStyles.settingsItem),
          CupertinoSegmentedControl<String>(
            selectedColor: Theme.of(context).colorScheme.primary,
            borderColor: Theme.of(context).colorScheme.primary,
            unselectedColor: Theme.of(context).colorScheme.surface,
            groupValue: selectedUnit,
            children: {
              CustomConstants.unitMmol: Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text(CustomConstants.unitMmol),
              ),
              CustomConstants.unitMg: Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text(CustomConstants.unitMg),
              ),
            },
            onValueChanged: (value) async {
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              await prefs.setBool(
                CustomConstants.glucoseUnitPrefKey,
                value == CustomConstants.unitMg,
              );
              setState(() {
                selectedUnit = value;
                glucoseUnitNotifier.value = value == CustomConstants.unitMg;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> confirmReset(
    BuildContext context,
    String currentPassword,
    String newPasword,
  ) async {
    if (authService.value.currentUser == null ||
        authService.value.currentUser!.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are not logged in, please login first.')),
      );
      return;
    }

    if (currentPassword.isEmpty || newPasword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password fields cannot be empty.")),
      );
      return;
    }

    try {
      await authService.value.updatePassword(
        email: authService.value.currentUser!.email!,
        password: currentPassword,
        newPassword: newPasword,
      );
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message!)));
      }
    } catch (e) {
      rethrow;
    }

    // All passed, password updated!
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Password has been updated!")));
    }
  }

  void updatePassword(BuildContext context) async {
    TextEditingController passwordController = TextEditingController();
    TextEditingController newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirm to update password"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Enter your current password"),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                const Text("Enter your new password"),
                TextField(
                  controller: newPassController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await confirmReset(
                  context,
                  passwordController.text,
                  newPassController.text,
                );
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void deleteAccount(BuildContext context) async {
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirm Account Deletion"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter your password to delete your account."),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await confirmDelete(context, passwordController.text);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> confirmDelete(BuildContext context, String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (password.isEmpty) {
        throw FirebaseAuthException(
          code: "no-password",
          message: "Please enter a valid password",
        );
      }

      if (user == null || user.email == null) {
        throw FirebaseAuthException(
          code: "user-not-found",
          message: "User not logged in",
        );
      }
      await authService.value.deleteAccount(
        email: user.email!,
        password: password,
      );

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "An error occured")),
        );
      }
    }
  }

  void logout(BuildContext context) async {
    try {
      await authService.value.signOut();

      if (!context.mounted) return;

      selectedPageNotifier.value = 0;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return LoginPage();
          },
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "An error occured")));
    }
  }

  Future<void> saveGlucoseThresholds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('min_glucose', minGlucose);
    await prefs.setDouble('max_glucose', maxGlucose);
  }
}
