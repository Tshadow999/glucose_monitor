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

  void addToBox(GlucoseReading newReading) {
    readingBox.put(newReading.timestamp.toString(), newReading);
  }

  void deleteFromBoxAt(int index) {
    readingBox.deleteAt(index);
  }

  void deleteAll() {
    final keys = readingBox.keys.toList();
    readingBox.deleteAll(keys);
  }

  List<GlucoseReading> getAllReadings() {
    final readings = readingBox.values.cast<GlucoseReading>().toList();
    readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return readings;
  }
}
