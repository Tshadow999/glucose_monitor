import 'package:flutter/material.dart';
import 'package:mobile_app/data/constants.dart';
import 'package:mobile_app/views/widgets/navigationbar_widget.dart';
import 'package:mobile_app/views/pages/home_page.dart';
import 'package:mobile_app/views/pages/settings_page.dart';
import 'package:mobile_app/data/notifiers.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Widget> pages = [HomePage(), SettingsPage()];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Continuous Glucose Monitoring"),
        actions: [
          IconButton(
            onPressed: () async {
              darkModeNotifier.value = !darkModeNotifier.value;

              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              await prefs.setBool(
                CustomConstants.themeModePrefKey,
                darkModeNotifier.value,
              );
            },
            icon: ValueListenableBuilder(
              valueListenable: darkModeNotifier,
              builder: (context, isDarkMode, child) {
                return Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode);
              },
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return pages.elementAt(selectedPage);
        },
      ),
      bottomNavigationBar: NavigationbarWidget(),
    );
  }
}
