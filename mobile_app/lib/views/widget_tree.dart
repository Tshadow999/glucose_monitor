import 'package:sugar_daddy/data/database_service.dart';
import 'package:flutter/material.dart';
import 'package:sugar_daddy/views/widgets/navigationbar_widget.dart';
import 'package:sugar_daddy/views/pages/home_page.dart';
import 'package:sugar_daddy/views/pages/settings_page.dart';
import 'package:sugar_daddy/data/notifiers.dart';

List<Widget> pages = [HomePage(), SettingsPage()];

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  void initState() {
    super.initState();
    DatabaseService.updateDocumentIds("user_data");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FutureBuilder(
          future: DatabaseService.getUserNameByEmail(
            authService.value.currentUser!.email ?? "",
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Text("Hello ${snapshot.data ?? "User"}");
            } else {
              return Text("");
            }
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
