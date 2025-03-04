import 'package:flutter/material.dart';

class NavigationbarWidget extends StatefulWidget {
  const NavigationbarWidget({super.key});

  @override
  State<NavigationbarWidget> createState() => _NavigationbarWidgetState();
}

class _NavigationbarWidgetState extends State<NavigationbarWidget> {
  int selectedPage = 0;
  @override
  Widget build(BuildContext ctx) {
    return NavigationBar(
      destinations: [
        NavigationDestination(icon: Icon(Icons.home), label: "Home"),
        NavigationDestination(icon: Icon(Icons.settings), label: "Settings"),
      ],
      onDestinationSelected:
          (value) => {
            setState(() {
              selectedPage = value;
            }),
          },
      selectedIndex: selectedPage,
    );
  }
}
