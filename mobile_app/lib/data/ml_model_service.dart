import 'dart:typed_data';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:flutter/services.dart' show rootBundle;

// run this
Future<List<double>> runModelFromCsv() async {
  print("----- STARTING AI -----");
  try {
    await MlModelService().init();

    List<List<double>> inputData = await MlModelService().loadCsvData();
    
    if (inputData.isEmpty) {
      print("No valid input data found!");
      return [];
    }
    
    print("Processing ${inputData.length} input segments");
    List<double> predictions = [];
    
    for (var input in inputData) {
      try {
        double result = await MlModelService().runModel(input);
        print('Prediction: $result');
        predictions.add(result); // Store the result
      } catch (e) {
        print('Error processing segment: $e');
        // Continue with next segment rather than failing entire batch
      }
    }
   
    if (predictions.isNotEmpty) {
      double average = predictions.reduce((a, b) => a + b) / predictions.length;
      print('Average prediction: $average');
    }
    
    return predictions;
  } catch (e) {
    print('Error in runModelFromCsv: $e');
    return [];
  }
}

class MlModelService {
  static final MlModelService _instance = MlModelService._internal();
  factory MlModelService() => _instance;
  MlModelService._internal();
  
  bool modelLoaded = false;
  double modelOutput = -1.0;
  
  Future<void> init() async {

    if (modelLoaded) return;
    
    try {
      String? res = await Tflite.loadModel(
        model: "assets/model.tflite",
        numThreads: 1,
        isAsset: true,
      );
      
      print("Model load result: $res");
      modelLoaded = true;
    } catch (e) {
      print("Error initializing model: $e");
      rethrow;
    }
  }
  
  Future<double> runModel(List<double> input) async {
    if (input.length != 120) {
      throw Exception("Input must have exactly 120 values, got ${input.length}");
    }
    
    try {
      // Reshape input to match model expectation [1, 120, 1]
      // But tflite_v2 expects a flat array, so we prepare accordingly
      final Float32List floatInput = Float32List.fromList(input);
      
      // Convert to byte buffer
      final inputBytes = floatInput.buffer.asUint8List();
      
      // Run the model
      var result = await Tflite.runModelOnBinary(
        binary: inputBytes,
        numResults: 1,
        threshold: 0.05,  // Lower threshold to ensure we get results
      );
      
      if (result != null && result.isNotEmpty) {
        print("Raw output: $result");
        
        // Extract the value - handle both formats of output
        final value = result.first['confidence'] ?? 
                     result.first['output'] ?? 
                     result.first['index'] ?? 
                     0.0;
                     
        return (value as num).toDouble();
      } else {
        throw Exception("No result returned from model");
      }
    } catch (e) {
      print("Error running model: $e");
      rethrow;
    }
  }
  
  Future<List<List<double>>> loadCsvData() async {
    try {
      final rawData = await rootBundle.loadString('assets/modelData.csv');
      final lines = rawData.trim().split("\n");
      List<List<double>> data = [];
      
      print("Processing ${lines.length} lines from CSV");
      
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
      print("Error loading CSV data: $e");
      return [];
    }
  }
  
  // Clean up resources when done
  Future<void> dispose() async {
    if (modelLoaded) {
      await Tflite.close();
      modelLoaded = false;
    }
  }
}