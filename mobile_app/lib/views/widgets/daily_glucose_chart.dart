import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:GlucoMonitor/data/constants.dart';
import 'package:GlucoMonitor/data/notifiers.dart';

class DailyGlucoseChart extends StatefulWidget {
  const DailyGlucoseChart({super.key});

  @override
  State<DailyGlucoseChart> createState() => _DailyGlucoseChartState();
}

class _DailyGlucoseChartState extends State<DailyGlucoseChart> {
  bool showAvg = false;
  List<FlSpot> glucoseLevels = [];

  Timer? _timer;

  double get unitMultiplier => glucoseUnitNotifier.value ? 18 : 1;

  String get glucoseUnitLabel =>
      glucoseUnitNotifier.value
          ? CustomConstants.unitMg
          : CustomConstants.unitMmol;

  double get lowThreshold => 3.9 * unitMultiplier;
  double get highThreshold => 7.0 * unitMultiplier;

  @override
  void initState() {
    super.initState();
    _generateDummyData();
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!mounted) return;
      _addNewGlucoseReading();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Glucose $glucoseUnitLabel",
                    style: CustomTextStyles.cardTitle(context),
                  ),
                  SizedBox(height: 500, child: LineChart(mainData())),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          averageGlucoseCard(context),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateDummyData() {
    DateTime now = DateTime.now();
    setState(() {
      glucoseLevels = List.generate(15, (index) {
        // Create time points 15 minutes apart
        DateTime time = now.subtract(Duration(minutes: (15 - index) * 15));

        // Base glucose level (mmol/L or mg/dL depending on your unit system)
        double baseLevel =
            5.5 * unitMultiplier; // Assuming 5.5 mmol/L as baseline

        // Create a realistic sine wave with some variation
        // Using multiple sine waves of different frequencies for more natural variation
        double sineValue =
            baseLevel + (2.0 * unitMultiplier * sin(index * 0.5));

        // Add some minor random noise for realism
        sineValue += (0.1 * unitMultiplier * (Random().nextDouble() - 0.5));

        return FlSpot(time.millisecondsSinceEpoch.toDouble(), sineValue);
      });
    });
  }

  void _addNewGlucoseReading() {
    DateTime now = DateTime.now();
    setState(() {
      glucoseLevels.add(FlSpot(now.millisecondsSinceEpoch.toDouble(), 4));
      if (glucoseLevels.length > 10) {
        glucoseLevels.removeAt(0);
      }
    });
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    String formattedTime =
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    return SideTitleWidget(
      meta: meta,
      child: Text(formattedTime, style: const TextStyle(fontSize: 12)),
    );
  }

  LineChartData mainData() {
    DateTime now = DateTime.now();

    double startTime = now.millisecondsSinceEpoch.toDouble();
    double range = Duration(hours: 8).inMilliseconds.toDouble();

    // Calculate the x-axis min and max to ensure we have a correct time window
    double minX = startTime - range / 2;
    double maxX = startTime + range / 2;

    return LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: true),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            maxIncluded: false,
            minIncluded: false,
            interval: Duration(hours: 1).inMilliseconds.toDouble(),
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            minIncluded: false,
            maxIncluded: false,
            reservedSize: 50,
            interval: 0.5 * unitMultiplier,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(meta: meta, child: Text("$value"));
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: true),
      minX: minX,
      maxX: maxX,
      minY: 2 * unitMultiplier,
      maxY: 8 * unitMultiplier,
      lineBarsData: [
        LineChartBarData(
          spots: glucoseLevels,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary,
            ],
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (
              FlSpot spot,
              double percent,
              LineChartBarData bardata,
              int index,
            ) {
              // Normal range color
              Color dotColor = getColorForValue(spot.y);

              return FlDotCirclePainter(
                radius: 6,
                color: dotColor,
                strokeWidth: 2,
                strokeColor: Colors.white, // Adds contrast
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors:
                  ([
                    Theme.of(context).colorScheme.onPrimary,
                    Theme.of(context).colorScheme.onPrimary,
                  ]).map((c) => c.withAlpha(60)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Color getColorForValue(double value) {
    if (value < lowThreshold) return Colors.red; // Too low
    if (value > highThreshold) return Colors.orangeAccent; // Too high
    return Colors.green; // Normal
  }

  Widget averageGlucoseCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            "Average: ${averageGlucoseLevel.toStringAsFixed(2)} $glucoseUnitLabel",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  double get averageGlucoseLevel {
    if (glucoseLevels.isEmpty) return 0;
    double sum = glucoseLevels.map((spot) => spot.y).reduce((a, b) => a + b);
    return sum / glucoseLevels.length;
  }
}
