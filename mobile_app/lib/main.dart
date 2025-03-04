import 'package:flutter/material.dart';
import 'package:mobile_app/navigationbar_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Continuous Glucose Monitoring App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("Continuous Glucose Monitoring"),
        ),
        body: Center(
          child: TextButton(onPressed: () {}, child: const Text('Next')),
        ),
        bottomNavigationBar: NavigationbarWidget(),
      ),
    );
  }
}
