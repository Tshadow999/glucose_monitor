import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:GlucoMonitor/data/constants.dart';
import 'package:GlucoMonitor/data/notifiers.dart';
import 'package:GlucoMonitor/views/pages/login_page.dart';
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
          Divider(),
          Text("Profile", style: CustomTextStyles.settingsTitle),
          Divider(),
          ListTile(
            title: Text("Logout"),
            onTap: () {
              selectedPageNotifier.value = 0;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return LoginPage();
                  },
                ),
              );
            },
          ),
          ListTile(
            title: Text(
              "Delete Account",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap:
                () => showDialog(
                  context: context,
                  builder:
                      (BuildContext context) => AlertDialog(
                        title: const Text(
                          "Are you sure you want to delete your account?",
                        ),
                        content: const Text("This action cannot be undone"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Delete account"),
                          ),
                        ],
                      ),
                ),
          ),
        ],
      ),
    );
  }
}
