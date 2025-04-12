import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

// run this
Future<List<double>> runModelFromCsv() async {
  // print("----- STARTING AI -----");
  try {
    List<List<double>> inputData = await MlModelService().loadCsvData();
    
    if (inputData.isEmpty) {
      print("No valid input data found!");
      return [];
    }
    
    // print("Processing ${inputData.length} input segments");
    List<double> predictions = [];
    
    for (var input in inputData) {
      try {
        double result = await MlModelService().runModelPrediction(input);
        // print('Prediction: $result');
        predictions.add(result); // Store the result
      } catch (e) {
        print('Error processing segment: $e');
        // Continue with next segment rather than failing entire batch
      }
    }
      
    return predictions;
  } catch (e) {
    rethrow;
  }
}

class MlModelService {
  static final MlModelService _instance = MlModelService._internal();
  factory MlModelService() => _instance;
  MlModelService._internal();
  
  bool modelLoaded = false;
  double modelOutput = -1.0;
  
  Future<List<List<double>>> loadCsvData() async {
    try {
      final rawData = await rootBundle.loadString('assets/modelData.csv');
      final lines = rawData.trim().split("\n");
      List<List<double>> data = [];
      
      //print("Processing ${lines.length} lines from CSV");
      
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        
        // Handle both comma and space-separated values
        List<String> parts = line.contains(',') 
            ? line.split(',') 
            : line.split(RegExp(r'\s+'));
            
        var values = parts
            .where((e) => e.trim().isNotEmpty)
            .map((e) => double.tryParse(e.trim()) ?? 0.0)
            .toList();
            
        if (values.length == 120) {
          data.add(values);
        } else if (values.length > 120) {
          data.add(values.sublist(0, 120));
          print("Truncated row from ${values.length} to 120 values");
        } else {
          print("Skipping invalid row: ${values.length} values (expected 120)");
        }
      }
      
      return data;
    } catch (e) {
      rethrow;
      }
  }

Future<double> runModelPrediction(List<double> inputData) async {
  const String apiUrl = "http://145.126.35.126:8000/predict/";
  final headers = {'Content-Type': 'application/json'};
  double prediction = -1.0;

  try {
      final Map<String, dynamic> inputJson = {
        'input': inputData,
      };

      // Send the POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(inputJson),
      );

      // Check if the response is successful (status code 200)
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        prediction = (data['prediction']);
        // print('Prediction: $prediction');

        return prediction;

      } else {
        // Handle unsuccessful response
        print('Error: Failed to get prediction, Status Code: ${response.statusCode}');
        return -1.0;
      }
    } catch (e) {
      rethrow;
    }
  }

}