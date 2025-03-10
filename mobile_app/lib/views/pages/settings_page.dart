import 'package:flutter/material.dart';
import 'package:mobile_app/data/constants.dart';
import 'package:mobile_app/data/notifiers.dart';
import 'package:mobile_app/views/pages/login_page.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
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
          Divider(),
          RadioListTile<String>(
            title: Text(CustomConstants.unitMmol),
            value: CustomConstants.unitMmol,

            groupValue: selectedUnit,
            onChanged: (value) async {
              glucoseUnitNotifier.value = value == CustomConstants.unitMg;

              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              await prefs.setBool(
                CustomConstants.glucoseUnitPrefKey,
                glucoseUnitNotifier.value,
              );
              setState(() {
                selectedUnit = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: Text(CustomConstants.unitMg),
            value: CustomConstants.unitMg,
            groupValue: selectedUnit,
            onChanged: (value) async {
              glucoseUnitNotifier.value = value == CustomConstants.unitMg;

              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              await prefs.setBool(
                CustomConstants.glucoseUnitPrefKey,
                glucoseUnitNotifier.value,
              );
              setState(() {
                selectedUnit = value!;
              });
            },
          ),
          Divider(),
        ],
      ),
    );
  }
}
