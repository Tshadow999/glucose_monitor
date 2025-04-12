import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

// run this
Future<double> runModelFromCsv() async {
  print("----- STARTING AI -----");
  await MlModelService().init();

  List<int> inputData = await MlModelService().loadCsvData();
  MlModelService().setModelInput(inputData);

  double result = await MlModelService().runModel();
  print('Prediction: $result');

  return result;
}

class MlModelService {
  static final MlModelService _instance =
      MlModelService._internal();
  factory MlModelService() => _instance;
  MlModelService._internal();


  late Interpreter interpreter;
  late List<List<double>> modelInput;
  double modelOutput = -1.0;

  Future<void> init() async{
    final options = InterpreterOptions();
  
    interpreter = await Interpreter.fromAsset(
      'assets/model.tflite',
        options: options,
      );
  }

  void setModelInput(List<int> input) {
    modelInput = [input.map((e) => e.toDouble()).toList()];
  }

  double getModelOutput() => modelOutput;

  Future<double> runModel() async {
    var output = List.filled(1, 0.0).reshape([1]);

    interpreter.run(modelInput, output);

    modelOutput = output[0][0];
    return modelOutput;
  }

Future<List<int>> loadCsvData() async {
  final rawData = await rootBundle.loadString('assets/modelData.csv');
  final lines = rawData.split('\n');
  final data = lines
      .where((line) => line.trim().isNotEmpty)
      .map((line) => int.tryParse(line.trim()) ?? 0)
      .toList();

  return data;
}
}