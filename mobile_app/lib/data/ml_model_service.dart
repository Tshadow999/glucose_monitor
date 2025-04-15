import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http_parser/http_parser.dart';

// run this
Future<double> runModelFromCsv(String path) async {
  try {
    double prediction = await MlModelService().uploadCsvFile(path);

    if (prediction == -1.0) {
      debugPrint("Error occurred while getting prediction!");
      return -1.0;
    }

    return prediction;

    } catch (e) {
      debugPrint('Error processing CSV file: $e');
      return -1.0;
    }
}

class MlModelService {
  static final MlModelService _instance = MlModelService._internal();
  factory MlModelService() => _instance;
  MlModelService._internal();

  // At home
  // final String apiUrl = "http://192.168.2.11:8000/predict/";
  // At uni
  final String apiUrl = "http://145.126.35.126:8000/predict/";


  // to run this server:
  // source ~/myenv/bin/activate
  // cd /glucose_monitor/fastAPI
  // uvicorn server:app --host 0.0.0.0 --port 8000

  Future<List<List<double>>> loadCsvData(String? path) async {
    try {
      final rawData = await rootBundle.loadString(
        path ?? 'assets/modelData.csv',
      );
      final lines = rawData.trim().split("\n");
      List<List<double>> data = [];

      //print("Processing ${lines.length} lines from CSV");

      for (var line in lines) {
        if (line.trim().isEmpty) continue;

        // Handle both comma and space-separated values
        List<String> parts =
            line.contains(',') ? line.split(',') : line.split(RegExp(r'\s+'));

        var values =
            parts
                .where((e) => e.trim().isNotEmpty)
                .map((e) => double.tryParse(e.trim()) ?? 0.0)
                .toList();

        if (values.length == 120) {
          data.add(values);
        } else if (values.length > 120) {
          data.add(values.sublist(0, 120));
          debugPrint("Truncated row from ${values.length} to 120 values");
        } else {
          debugPrint(
            "Skipping invalid row: ${values.length} values (expected 120)",
          );
        }
      }

      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<double> uploadCsvFile(String filePath) async {
    try {
      final uri = Uri.parse(apiUrl);
      final request = http.MultipartRequest('POST', uri);

      // Load file from assets
      final byteData = await rootBundle.load(filePath);
      final csvBytes = byteData.buffer.asUint8List();

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          csvBytes,
          filename: 'modelData.csv',
          contentType: MediaType('text', 'csv'),
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        final prediction = (data['prediction'] as num).toDouble();
        return prediction;
      } else {
        debugPrint('❌ Server responded with status: ${response.statusCode}');
        return -1.0;
      }
    } catch (e) {
      debugPrint('❌ Exception during CSV upload: $e');
      return -1.0;
    }
  }
}
