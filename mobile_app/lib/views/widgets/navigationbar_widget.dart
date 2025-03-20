import 'package:flutter/material.dart';
import 'package:GlucoMonitor/data/notifiers.dart';

class NavigationbarWidget extends StatelessWidget {
  const NavigationbarWidget({super.key});

  @override
  Widget build(BuildContext ctx) {
    return ValueListenableBuilder(
      valueListenable: selectedPageNotifier,
      builder:
          (context, selectedPage, child) => NavigationBar(
            destinations: [
              NavigationDestination(icon: Icon(Icons.home), label: "Home"),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: "Settings",
              ),
            ],
            onDestinationSelected: (int value) {
              selectedPageNotifier.value = value;
            },
            selectedIndex: selectedPage,
          ),
    );
  }
}
