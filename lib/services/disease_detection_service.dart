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
      // Load the NEW MODEL: model.tflite
      _interpreter = await Interpreter.fromAsset('assets/model/model.tflite');
      _isLoaded = true;
      print('✅ New model loaded: model.tflite');
      print('📋 Classes loaded: ${_labels.length}');
    } catch (e) {
      throw Exception('Failed to load model or labels: $e');
    }
  }

  Future<Map<String, dynamic>> classify(File imageFile, {String normalizationMethod = 'method1'}) async {
    await loadModel();
    if (_interpreter == null || _labels.isEmpty) {
      throw Exception('Model or labels not loaded');
    }
    // Decode and preprocess image
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Failed to decode image');
    final resized = img.copyResize(image, width: 224, height: 224);
    
    // Try different normalization methods
    List<List<List<List<double>>>> input;
    
    switch (normalizationMethod) {
      case 'method1': // [0, 1] normalization
        print('🔧 Using Method 1: [0, 1] normalization (divide by 255)');
        input = List.generate(1, (_) => List.generate(224, (y) => List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        })));
        break;
        
      case 'method2': // [-1, 1] normalization (MobileNet/Inception style)
        print('🔧 Using Method 2: [-1, 1] normalization (subtract 127.5, divide by 127.5)');
        input = List.generate(1, (_) => List.generate(224, (y) => List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            (pixel.r - 127.5) / 127.5,
            (pixel.g - 127.5) / 127.5,
            (pixel.b - 127.5) / 127.5
          ];
        })));
        break;
        
      case 'method3': // ImageNet normalization (ResNet/EfficientNet style)
        print('🔧 Using Method 3: ImageNet normalization');
        input = List.generate(1, (_) => List.generate(224, (y) => List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            (pixel.r / 255.0 - 0.485) / 0.229,
            (pixel.g / 255.0 - 0.456) / 0.224,
            (pixel.b / 255.0 - 0.406) / 0.225
          ];
        })));
        break;
        
      default:
        input = List.generate(1, (_) => List.generate(224, (y) => List.generate(224, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        })));
    }
    
    // Prepare output
    final output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
    // Run inference
    final startTime = DateTime.now();
    _interpreter!.run(input, output);
    final inferenceTime = DateTime.now().difference(startTime).inMilliseconds;
    
    final scores = output[0] as List<double>;
    
    // Apply softmax if needed (if scores not already probabilities)
    List<double> probabilities = scores;
    if (scores.any((x) => x > 1.0 || x < 0.0)) {
      final expScores = scores.map((x) => math.exp(x)).toList();
      final sumExp = expScores.reduce((a, b) => a + b);
      probabilities = expScores.map((x) => x / sumExp).toList();
    }
    
    // Find top 3 predictions
    final indexedScores = List.generate(
      probabilities.length, 
      (i) => {'index': i, 'score': probabilities[i]}
    )..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    final top1 = indexedScores[0];
    final top2 = indexedScores.length > 1 ? indexedScores[1] : null;
    final top3 = indexedScores.length > 2 ? indexedScores[2] : null;
    
    // Print detailed accuracy information to terminal
    print('\n' + '='*60);
    print('🔬 DISEASE DETECTION RESULT');
    print('='*60);
    print('⏱️  Inference Time: ${inferenceTime}ms');
    print('');
    print('📊 TOP PREDICTIONS:');
    print('   1️⃣  ${_labels[top1['index'] as int]}');
    print('       Confidence: ${((top1['score'] as double) * 100).toStringAsFixed(2)}%');
    if (top2 != null) {
      print('   2️⃣  ${_labels[top2['index'] as int]}');
      print('       Confidence: ${((top2['score'] as double) * 100).toStringAsFixed(2)}%');
    }
    if (top3 != null) {
      print('   3️⃣  ${_labels[top3['index'] as int]}');
      print('       Confidence: ${((top3['score'] as double) * 100).toStringAsFixed(2)}%');
    }
    print('');
    print('📈 ALL CLASS PROBABILITIES:');
    for (int i = 0; i < _labels.length; i++) {
      final percentage = (probabilities[i] * 100).toStringAsFixed(2);
      final bar = '█' * ((probabilities[i] * 50).round());
      print('   ${_labels[i].padRight(30)} $percentage% $bar');
    }
    print('='*60 + '\n');
    
    return {
      'label': _labels[top1['index'] as int],
      'confidence': top1['score'] as double,
      'allScores': probabilities,
      'inferenceTime': inferenceTime,
      'top3': [
        {'label': _labels[top1['index'] as int], 'confidence': top1['score']},
        if (top2 != null) {'label': _labels[top2['index'] as int], 'confidence': top2['score']},
        if (top3 != null) {'label': _labels[top3['index'] as int], 'confidence': top3['score']},
      ],
    };
  }
}
