import 'package:hive_flutter/adapters.dart';

part 'local_storage.g.dart';

@HiveType(typeId: 0)
class GlucoseReading extends HiveObject {
  @HiveField(0)
  double value;

  @HiveField(1)
  DateTime timestamp;

  GlucoseReading({required this.value, required this.timestamp});
}

class GlucoseReadingService {
  static final GlucoseReadingService _instance =
      GlucoseReadingService._internal();
  factory GlucoseReadingService() => _instance;
  GlucoseReadingService._internal();

  final String readingBoxName = "readingBox";

  late Box readingBox;

  Future<void> initHive() async {
    await Hive.initFlutter();

    Hive.registerAdapter(GlucoseReadingAdapter());

    readingBox = await Hive.openBox('testBox');
  }

  String getCurrentWeekKey() {
    final now = DateTime.now();
    final year = now.year;
    final weekOfYear = getWeekOfYear(now);
    return '$year-$weekOfYear';
  }

  int getWeekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final difference = date.difference(startOfYear).inDays;
    return (difference / 7).floor() + 1;
  }

  void clearOldData() {
    final currentWeekKey = getCurrentWeekKey();
    final keys = readingBox.keys.toList();

    for (var key in keys) {
      if (!key.startsWith(currentWeekKey)) {
        readingBox.delete(key);
      }
    }
  }

  void addReadings(List<double> predictions) {
    clearOldData();

    for (int i = 0; i < predictions.length; i++) {
      addReading(predictions[i], DateTime.now().subtract(Duration(minutes: 10 * i)));
    } 
  }

  void addReading(double value, DateTime time) {
    GlucoseReading newReading = GlucoseReading(value: value, timestamp: time);

    // Store the data with the key of the current week and year
    final currentWeekKey = getCurrentWeekKey();
    readingBox.put('$currentWeekKey-${time.toString()}', newReading);
  }

  void deleteFromBoxAt(int index) {
    readingBox.deleteAt(index);
  }

  Future<void> deleteAll() async {
    final keys = readingBox.keys.toList();
    await readingBox.deleteAll(keys);
  }

  List<GlucoseReading> getTodayReadings() {
    final readings = readingBox.values.cast<GlucoseReading>().toList();
  
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    final todaysReadings = readings.where((reading) {
      final timestamp = reading.timestamp;
      return timestamp.isAfter(startOfDay.subtract(Duration(seconds: 1))) && timestamp.isBefore(now.add(Duration(days: 1)));
    }).toList();

    todaysReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return todaysReadings;
  }
}