import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Diagnostic tool to analyze model input/output and identify accuracy issues
class ModelDiagnostic {
  
  static Future<void> runDiagnostics() async {
    print('\n' + '='*70);
    print('🔍 MODEL DIAGNOSTICS');
    print('='*70);
    
    try {
      // Load model
      final interpreter = await Interpreter.fromAsset('assets/model/model.tflite');
      
      // Get input tensor details
      final inputTensors = interpreter.getInputTensors();
      final outputTensors = interpreter.getOutputTensors();
      
      print('\n📥 INPUT TENSOR DETAILS:');
      for (var i = 0; i < inputTensors.length; i++) {
        final tensor = inputTensors[i];
        print('  Tensor $i:');
        print('    Shape: ${tensor.shape}');
        print('    Type: ${tensor.type}');
        print('    Name: ${tensor.name}');
      }
      
      print('\n📤 OUTPUT TENSOR DETAILS:');
      for (var i = 0; i < outputTensors.length; i++) {
        final tensor = outputTensors[i];
        print('  Tensor $i:');
        print('    Shape: ${tensor.shape}');
        print('    Type: ${tensor.type}');
        print('    Name: ${tensor.name}');
      }
      
      // Load labels
      final labelsData = await rootBundle.loadString('assets/model/labels.txt');
      final labels = labelsData.split('\n').where((l) => l.trim().isNotEmpty).toList();
      
      print('\n📋 LABELS (${labels.length} classes):');
      for (var i = 0; i < labels.length; i++) {
        print('  $i: ${labels[i]}');
      }
      
      // Check for common issues
      print('\n⚠️  POTENTIAL ISSUES:');
      
      final inputShape = inputTensors[0].shape;
      if (inputShape[1] != 224 || inputShape[2] != 224) {
        print('  ❌ Input size mismatch! Expected 224x224, got ${inputShape[1]}x${inputShape[2]}');
      } else {
        print('  ✅ Input size correct: 224x224');
      }
      
      final outputShape = outputTensors[0].shape;
      if (outputShape[1] != labels.length) {
        print('  ❌ Output classes mismatch! Model outputs ${outputShape[1]} but labels has ${labels.length}');
      } else {
        print('  ✅ Output classes match labels: ${labels.length}');
      }
      
      // Check input type
      final inputType = inputTensors[0].type;
      print('  ℹ️  Input type: $inputType (should be float32)');
      
      print('\n💡 PREPROCESSING RECOMMENDATIONS:');
      print('  1. Image should be resized to ${inputShape[1]}x${inputShape[2]}');
      print('  2. Pixel values should be normalized:');
      print('     - Option A: [0, 1] range (divide by 255)');
      print('     - Option B: [-1, 1] range (subtract 127.5, divide by 127.5)');
      print('     - Option C: ImageNet normalization (mean=[0.485,0.456,0.406], std=[0.229,0.224,0.225])');
      print('  3. Channel order: RGB (not BGR)');
      
      print('\n🔬 COMMON LOW ACCURACY CAUSES:');
      print('  1. ❌ Wrong normalization (e.g., model trained with [-1,1] but using [0,1])');
      print('  2. ❌ Wrong image resize method (should preserve aspect ratio)');
      print('  3. ❌ Label order mismatch (labels.txt order ≠ model output order)');
      print('  4. ❌ Channel order wrong (RGB vs BGR)');
      print('  5. ❌ Model not trained well (low validation accuracy during training)');
      print('  6. ❌ Test images different from training images (lighting, angle, etc.)');
      
      interpreter.close();
      
      print('='*70 + '\n');
      
    } catch (e) {
      print('❌ Diagnostic failed: $e');
    }
  }
  
  /// Test different normalization methods
  static Map<String, dynamic> testNormalizations(img.Image image) {
    final resized = img.copyResize(image, width: 224, height: 224);
    
    print('\n🧪 TESTING NORMALIZATION METHODS:');
    
    // Method 1: [0, 1]
    final method1 = List.generate(224, (y) => List.generate(224, (x) {
      final pixel = resized.getPixel(x, y);
      return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
    }));
    
    // Method 2: [-1, 1]
    final method2 = List.generate(224, (y) => List.generate(224, (x) {
      final pixel = resized.getPixel(x, y);
      return [
        (pixel.r - 127.5) / 127.5,
        (pixel.g - 127.5) / 127.5,
        (pixel.b - 127.5) / 127.5
      ];
    }));
    
    // Method 3: ImageNet normalization
    final method3 = List.generate(224, (y) => List.generate(224, (x) {
      final pixel = resized.getPixel(x, y);
      return [
        (pixel.r / 255.0 - 0.485) / 0.229,
        (pixel.g / 255.0 - 0.456) / 0.224,
        (pixel.b / 255.0 - 0.406) / 0.225
      ];
    }));
    
    print('  Method 1 [0,1]: Sample pixel = ${method1[112][112]}');
    print('  Method 2 [-1,1]: Sample pixel = ${method2[112][112]}');
    print('  Method 3 ImageNet: Sample pixel = ${method3[112][112]}');
    
    return {
      'method1': method1,
      'method2': method2,
      'method3': method3,
    };
  }
}
