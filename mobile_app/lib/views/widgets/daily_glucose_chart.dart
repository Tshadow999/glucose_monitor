import 'dart:math';

import 'package:sugar_daddy/data/notification_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:sugar_daddy/data/constants.dart';
import 'package:sugar_daddy/data/notifiers.dart';

class DailyGlucoseChart extends StatefulWidget {
  const DailyGlucoseChart({super.key});

  @override
  State<DailyGlucoseChart> createState() => _DailyGlucoseChartState();
}

class _DailyGlucoseChartState extends State<DailyGlucoseChart> {
  bool showAvg = false;
  List<FlSpot> glucoseLevels = [];

  Timer? timer;

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
    generateDummyData();
    timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!mounted) return;
      addNewGlucoseReading();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.0),
      child: Expanded(
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
                    SizedBox(height: 450, child: LineChart(mainData())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            averageGlucoseCard(context),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void generateDummyData() {
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

  void addNewGlucoseReading() {
    DateTime now = DateTime.now();
    setState(() {
      int lastIndex = glucoseLevels.length;
      double baseLevel = 5.5 * unitMultiplier;

      double sineValue =
          baseLevel + (2.0 * unitMultiplier * sin(lastIndex * 0.5));

      sineValue += (0.1 * unitMultiplier * (Random().nextDouble() - 0.5));

      checkThresholdAndNotify(sineValue);

      glucoseLevels.add(
        FlSpot(now.millisecondsSinceEpoch.toDouble(), sineValue),
      );

      if (glucoseLevels.length > 10) {
        glucoseLevels.removeAt(0);
      }
    });
  }

  void checkThresholdAndNotify(double glucoseValue) {
    if (glucoseValue < lowThreshold) {
      NotificationService().show(
        id: 1,
        title: "Low Glucose Alert",
        body:
            "Your glucose level is ${glucoseValue.toStringAsFixed(1)} $glucoseUnitLabel. Take action!",
      );
    } else if (glucoseValue > highThreshold) {
      NotificationService().show(
        id: 2,
        title: "High Glucose Alert",
        body:
            "Your glucose level is ${glucoseValue.toStringAsFixed(1)} $glucoseUnitLabel. Take action!",
      );
    }
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
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipPadding: const EdgeInsets.all(8),
          tooltipRoundedRadius: 8,
          tooltipBorder: BorderSide(
            color: Theme.of(context).colorScheme.inversePrimary,
            width: 3,
          ),
          getTooltipColor: (LineBarSpot touchedSpot) {
            return Theme.of(context).colorScheme.onPrimaryFixed;
          },
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              // decimal places depending on unit.
              int decimalPlaces = spot.y < 10 ? 2 : 1;
              String formattedValue = spot.y.toStringAsFixed(decimalPlaces);
              return LineTooltipItem(
                formattedValue,
                CustomTextStyles.chartToolTip,
              );
            }).toList();
          },
        ),
        touchCallback: (p0, p1) {},
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: lowThreshold,
            color: Colors.red.withAlpha(200),
            strokeWidth: 2,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 8, top: 2),
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              labelResolver:
                  (line) => 'Low: ${lowThreshold.toStringAsFixed(1)}',
            ),
          ),
          HorizontalLine(
            y: highThreshold,
            color: Colors.orange.withAlpha(200),
            strokeWidth: 2,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 8, top: 2),
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              labelResolver:
                  (line) => 'High: ${highThreshold.toStringAsFixed(1)}',
            ),
          ),
        ],
      ),
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
