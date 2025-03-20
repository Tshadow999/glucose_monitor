import 'package:flutter/material.dart';
import 'package:GlucoMonitor/views/widgets/navigationbar_widget.dart';
import 'package:GlucoMonitor/views/pages/home_page.dart';
import 'package:GlucoMonitor/views/pages/settings_page.dart';
import 'package:GlucoMonitor/data/notifiers.dart';

List<Widget> pages = [HomePage(), SettingsPage()];
List<String> pageTitles = ["Home", "Settings"];

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: ValueListenableBuilder(
          valueListenable: selectedPageNotifier,
          builder: (context, selectedPage, child) {
            return Text(pageTitles.elementAt(selectedPage).toString());
          },
        ),
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
