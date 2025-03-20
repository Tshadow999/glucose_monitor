import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:mobile_app/data/constants.dart';
import 'package:mobile_app/data/notification_service.dart';
import 'package:mobile_app/data/notifiers.dart';

class DailyGlucoseChart extends StatefulWidget {
  const DailyGlucoseChart({super.key});

  @override
  State<DailyGlucoseChart> createState() => _DailyGlucoseChartState();
}

class _DailyGlucoseChartState extends State<DailyGlucoseChart> {
  bool showAvg = false;
  List<FlSpot> glucoseLevels = [];

  Timer? _timer;
  String glucoseUnit = CustomConstants.unitMg;

  @override
  void initState() {
    super.initState();
    _generateDummyData();
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!mounted) return;
      _addNewGlucoseReading();
    });

    glucoseUnit =
        glucoseUnitNotifier.value
            ? CustomConstants.unitMg
            : CustomConstants.unitMmol;
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
                    "Glucose $glucoseUnit",
                    style: CustomTextStyles.cardTitle(context),
                  ),
                  SizedBox(height: 500, child: LineChart(mainData())),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              NotificationService().cancelAll();
              NotificationService().show(
                title: "Warning",
                body:
                    "Your glucose level is above the threshold.\nConsider taking action!",
              );

              NotificationService().schedule(
                title: "Scheduled notification",
                body: "This took some time to get there",
                hour: 16,
                minute: 18,
              );
            },
            child: Text("Notification test"),
          ),
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
      glucoseLevels = List.generate(10, (index) {
        DateTime time = now.subtract(Duration(minutes: (10 - index) * 15));
        return FlSpot(
          time.millisecondsSinceEpoch.toDouble(),
          (4 * (glucoseUnitNotifier.value ? 18 : 1) +
              (index % 2 == 0 ? 0.5 : -0.5)),
        );
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
            interval: 0.5 * (glucoseUnitNotifier.value ? 20 : 1),
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
      minY: 2 * (glucoseUnitNotifier.value ? 18 : 1),
      maxY: 8 * (glucoseUnitNotifier.value ? 18 : 1),
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
          dotData: const FlDotData(show: true),
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
}
