import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class DiseaseDetectionService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      // Load labels
      final labelsData = await rootBundle.loadString('assets/model/labels.txt');
      _labels = labelsData.split('\n').where((l) => l.trim().isNotEmpty).toList();
      // Load model
      _interpreter = await Interpreter.fromAsset('assets/model/paddyai_modelv2.tflite');
      _isLoaded = true;
    } catch (e) {
      throw Exception('Failed to load model or labels: $e');
    }
  }

  Future<Map<String, dynamic>> classify(File imageFile) async {
    await loadModel();
    if (_interpreter == null || _labels.isEmpty) {
      throw Exception('Model or labels not loaded');
    }
    // Decode and preprocess image
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Failed to decode image');
    final resized = img.copyResize(image, width: 224, height: 224);
    // Convert to [1,224,224,3] float32 normalized 0-1
    final input = List.generate(1, (_) => List.generate(224, (y) => List.generate(224, (x) {
      final pixel = resized.getPixel(x, y);
      return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
    })));
    // Prepare output
    final output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
    // Run inference
    _interpreter!.run(input, output);
    final scores = output[0] as List<double>;
    // Find top label
    int topIdx = 0;
    double topScore = scores[0];
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > topScore) {
        topScore = scores[i];
        topIdx = i;
      }
    }
    // Optionally apply softmax if needed (if scores not already probabilities)
    if (topScore > 1.0) {
      final expScores = scores.map((x) => math.exp(x)).toList();
      final sumExp = expScores.reduce((a, b) => a + b);
      final probs = expScores.map((x) => x / sumExp).toList();
      topScore = probs[topIdx];
    }
    return {
      'label': _labels[topIdx],
      'confidence': topScore,
    };
  }
}
