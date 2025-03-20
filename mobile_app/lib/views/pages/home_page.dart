import 'package:flutter/material.dart';
import 'package:GlucoMonitor/views/widgets/daily_glucose_chart.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DailyGlucoseChart(),
    );
  }
}
