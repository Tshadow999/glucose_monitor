import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sugar_daddy/data/constants.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Divider(),
          Text("Customization", style: CustomTextStyles.settingsTitle),
          Divider(),
          SwitchListTile(
            title: Text(
              "Dark Mode",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Glucose Unit",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                CupertinoSegmentedControl<String>(
                  selectedColor: Theme.of(context).colorScheme.primary,
                  borderColor: Theme.of(context).colorScheme.primary,
                  unselectedColor: Theme.of(context).colorScheme.surface,
                  groupValue: selectedUnit,
                  children: {
                    CustomConstants.unitMmol: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Text(CustomConstants.unitMmol),
                    ),
                    CustomConstants.unitMg: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
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
                      glucoseUnitNotifier.value =
                          value == CustomConstants.unitMg;
                    });
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Divider(),
          Text("Profile", style: CustomTextStyles.settingsTitle),
          Divider(),
          ListTile(
            title: Text("Logout"),
            onTap: () {
              logout(context);
            },
          ),
          ListTile(
            title: Text("Update Password"),
            onTap: () => updatePassword(context),
          ),
          ListTile(
            title: Text(
              "Delete Account",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => deleteAccount(context),
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
}
