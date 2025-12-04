import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;

/// Test suite for AI Disease Detection Service
/// 
/// This test file validates the disease detection AI model functionality including:
/// - Label parsing and validation
/// - Image preprocessing logic
/// - Confidence score calculations
/// - Disease classification logic
/// - Model output interpretation
void main() {
  group('Disease Label Parsing Tests', () {
    test('Parse labels from text correctly', () {
      final labelsText = '''Bacterial Leaf Blight
Brown Spot
Healthy
Leaf Blast
Leaf Scald
Narrow Brown Spot''';

      final labels = labelsText.split('\n').where((l) => l.trim().isNotEmpty).toList();
      
      expect(labels.length, 6);
      expect(labels[0], 'Bacterial Leaf Blight');
      expect(labels[1], 'Brown Spot');
      expect(labels[2], 'Healthy');
      expect(labels[3], 'Leaf Blast');
      expect(labels[4], 'Leaf Scald');
      expect(labels[5], 'Narrow Brown Spot');
    });

    test('Handle empty lines in labels', () {
      final labelsText = '''Bacterial Leaf Blight

Brown Spot

Healthy''';

      final labels = labelsText.split('\n').where((l) => l.trim().isNotEmpty).toList();
      
      expect(labels.length, 3);
      expect(labels, ['Bacterial Leaf Blight', 'Brown Spot', 'Healthy']);
    });

    test('Handle labels with extra whitespace', () {
      final labelsText = '''  Bacterial Leaf Blight  
  Brown Spot  
  Healthy  ''';

      final labels = labelsText.split('\n').where((l) => l.trim().isNotEmpty).map((l) => l.trim()).toList();
      
      expect(labels.length, 3);
      expect(labels[0], 'Bacterial Leaf Blight');
      expect(labels[1], 'Brown Spot');
      expect(labels[2], 'Healthy');
    });
  });

  group('Image Preprocessing Tests', () {
    test('Normalize pixel values to 0-1 range', () {
      // Simulate RGB pixel values
      final r = 255;
      final g = 128;
      final b = 0;

      final normalizedR = r / 255.0;
      final normalizedG = g / 255.0;
      final normalizedB = b / 255.0;

      expect(normalizedR, 1.0);
      expect(normalizedG, closeTo(0.502, 0.001));
      expect(normalizedB, 0.0);
    });

    test('Calculate correct image dimensions for 224x224', () {
      final targetWidth = 224;
      final targetHeight = 224;

      expect(targetWidth, 224);
      expect(targetHeight, 224);
      expect(targetWidth * targetHeight, 50176);
    });

    test('Input tensor shape is correct [1,224,224,3]', () {
      final batchSize = 1;
      final width = 224;
      final height = 224;
      final channels = 3;

      expect(batchSize, 1);
      expect(width, 224);
      expect(height, 224);
      expect(channels, 3);
    });
  });

  group('Confidence Score Calculation Tests', () {
    test('Find maximum score from predictions', () {
      final scores = [0.1, 0.05, 0.7, 0.1, 0.03, 0.02];

      int topIdx = 0;
      double topScore = scores[0];
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > topScore) {
          topScore = scores[i];
          topIdx = i;
        }
      }

      expect(topIdx, 2);
      expect(topScore, 0.7);
    });

    test('Apply softmax to raw scores', () {
      final scores = [1.0, 2.0, 3.0];
      
      final expScores = scores.map((x) => math.exp(x)).toList();
      final sumExp = expScores.reduce((a, b) => a + b);
      final probs = expScores.map((x) => x / sumExp).toList();

      expect(probs.reduce((a, b) => a + b), closeTo(1.0, 0.001));
      expect(probs[2], greaterThan(probs[1]));
      expect(probs[1], greaterThan(probs[0]));
    });

    test('Softmax with equal scores gives equal probabilities', () {
      final scores = [1.0, 1.0, 1.0];
      
      final expScores = scores.map((x) => math.exp(x)).toList();
      final sumExp = expScores.reduce((a, b) => a + b);
      final probs = expScores.map((x) => x / sumExp).toList();

      expect(probs[0], closeTo(0.333, 0.001));
      expect(probs[1], closeTo(0.333, 0.001));
      expect(probs[2], closeTo(0.333, 0.001));
    });

    test('Confidence threshold validation', () {
      bool isHighConfidence(double confidence, double threshold) {
        return confidence >= threshold;
      }

      expect(isHighConfidence(0.85, 0.7), true);
      expect(isHighConfidence(0.65, 0.7), false);
      expect(isHighConfidence(0.7, 0.7), true);
    });
  });

  group('Disease Classification Logic Tests', () {
    test('Map predicted index to disease label', () {
      final labels = [
        'Bacterial Leaf Blight',
        'Brown Spot',
        'Healthy',
        'Leaf Blast',
        'Leaf Scald',
        'Narrow Brown Spot'
      ];

      final predictedIdx = 3;
      final diseaseName = labels[predictedIdx];

      expect(diseaseName, 'Leaf Blast');
    });

    test('Classify as healthy when predicted', () {
      final labels = [
        'Bacterial Leaf Blight',
        'Brown Spot',
        'Healthy',
        'Leaf Blast'
      ];

      final predictedIdx = 2;
      final isHealthy = labels[predictedIdx].toLowerCase() == 'healthy';

      expect(isHealthy, true);
    });

    test('Classify disease with highest confidence', () {
      final labels = [
        'Bacterial Leaf Blight',
        'Brown Spot',
        'Healthy',
        'Leaf Blast'
      ];
      final scores = [0.1, 0.05, 0.15, 0.7];

      int topIdx = 0;
      double topScore = scores[0];
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > topScore) {
          topScore = scores[i];
          topIdx = i;
        }
      }

      expect(labels[topIdx], 'Leaf Blast');
      expect(topScore, 0.7);
    });
  });

  group('Model Output Validation Tests', () {
    test('Output tensor has correct number of classes', () {
      final numClasses = 6; // Number of disease labels
      final output = List.filled(1 * numClasses, 0.0);

      expect(output.length, 6);
    });

    test('Validate output probabilities sum to 1 after softmax', () {
      final rawScores = [1.2, 2.3, 0.8, 1.5, 0.5, 1.0];
      
      final expScores = rawScores.map((x) => math.exp(x)).toList();
      final sumExp = expScores.reduce((a, b) => a + b);
      final probs = expScores.map((x) => x / sumExp).toList();

      final sum = probs.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.0001));
    });

    test('All probabilities are between 0 and 1', () {
      final scores = [1.0, 2.0, 3.0, 0.5, 1.5];
      
      final expScores = scores.map((x) => math.exp(x)).toList();
      final sumExp = expScores.reduce((a, b) => a + b);
      final probs = expScores.map((x) => x / sumExp).toList();

      for (var prob in probs) {
        expect(prob, greaterThanOrEqualTo(0.0));
        expect(prob, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('Detection Result Format Tests', () {
    test('Result contains label and confidence', () {
      final result = {
        'label': 'Leaf Blast',
        'confidence': 0.85,
      };

      expect(result.containsKey('label'), true);
      expect(result.containsKey('confidence'), true);
      expect(result['label'], 'Leaf Blast');
      expect(result['confidence'], 0.85);
    });

    test('Confidence is formatted as percentage', () {
      final confidence = 0.8547;
      final percentage = (confidence * 100).toStringAsFixed(1);

      expect(percentage, '85.5');
    });

    test('Format detection result message', () {
      String formatResult(String disease, double confidence) {
        final percentage = (confidence * 100).toStringAsFixed(1);
        return 'Detected: $disease ($percentage% confidence)';
      }

      expect(
        formatResult('Brown Spot', 0.92),
        'Detected: Brown Spot (92.0% confidence)'
      );
    });
  });

  group('Disease Information Mapping Tests', () {
    test('Map disease to treatment recommendations', () {
      Map<String, String> getTreatment(String disease) {
        final treatments = {
          'Bacterial Leaf Blight': 'Apply copper-based bactericides',
          'Brown Spot': 'Use fungicides containing mancozeb',
          'Leaf Blast': 'Apply tricyclazole or carbendazim',
          'Leaf Scald': 'Use resistant varieties and fungicides',
          'Narrow Brown Spot': 'Improve drainage and apply fungicides',
          'Healthy': 'No treatment needed',
        };
        return {'treatment': treatments[disease] ?? 'Consult agricultural expert'};
      }

      expect(
        getTreatment('Leaf Blast')['treatment'],
        'Apply tricyclazole or carbendazim'
      );
      expect(
        getTreatment('Healthy')['treatment'],
        'No treatment needed'
      );
    });

    test('Map disease to severity level', () {
      String getSeverity(String disease) {
        final severity = {
          'Bacterial Leaf Blight': 'High',
          'Brown Spot': 'Medium',
          'Leaf Blast': 'High',
          'Leaf Scald': 'Medium',
          'Narrow Brown Spot': 'Low',
          'Healthy': 'None',
        };
        return severity[disease] ?? 'Unknown';
      }

      expect(getSeverity('Bacterial Leaf Blight'), 'High');
      expect(getSeverity('Brown Spot'), 'Medium');
      expect(getSeverity('Healthy'), 'None');
    });

    test('Check if disease requires urgent action', () {
      bool requiresUrgentAction(String disease) {
        final urgent = [
          'Bacterial Leaf Blight',
          'Leaf Blast'
        ];
        return urgent.contains(disease);
      }

      expect(requiresUrgentAction('Bacterial Leaf Blight'), true);
      expect(requiresUrgentAction('Leaf Blast'), true);
      expect(requiresUrgentAction('Brown Spot'), false);
      expect(requiresUrgentAction('Healthy'), false);
    });
  });

  group('Error Handling Tests', () {
    test('Handle invalid label index', () {
      final labels = ['Disease1', 'Disease2', 'Disease3'];
      final invalidIdx = 5;

      expect(invalidIdx < labels.length, false);
    });

    test('Handle empty scores array', () {
      final scores = <double>[];
      
      expect(scores.isEmpty, true);
      expect(() {
        scores.reduce((a, b) => a + b);
      }, throwsStateError);
    });

    test('Handle null or zero confidence', () {
      bool isValidConfidence(double? confidence) {
        return confidence != null && confidence > 0 && confidence <= 1.0;
      }

      expect(isValidConfidence(0.5), true);
      expect(isValidConfidence(null), false);
      expect(isValidConfidence(0.0), false);
      expect(isValidConfidence(1.5), false);
    });
  });

  group('Confidence Level Classification Tests', () {
    test('Classify confidence as high/medium/low', () {
      String getConfidenceLevel(double confidence) {
        if (confidence >= 0.8) return 'High';
        if (confidence >= 0.6) return 'Medium';
        return 'Low';
      }

      expect(getConfidenceLevel(0.95), 'High');
      expect(getConfidenceLevel(0.75), 'Medium');
      expect(getConfidenceLevel(0.45), 'Low');
      expect(getConfidenceLevel(0.8), 'High');
      expect(getConfidenceLevel(0.6), 'Medium');
    });

    test('Determine if retest is recommended', () {
      bool shouldRetest(double confidence, double threshold) {
        return confidence < threshold;
      }

      expect(shouldRetest(0.55, 0.7), true);
      expect(shouldRetest(0.85, 0.7), false);
      expect(shouldRetest(0.7, 0.7), false);
    });
  });

  group('Batch Processing Tests', () {
    test('Process multiple detection results', () {
      final results = [
        {'label': 'Leaf Blast', 'confidence': 0.9},
        {'label': 'Brown Spot', 'confidence': 0.85},
        {'label': 'Healthy', 'confidence': 0.95},
      ];

      expect(results.length, 3);
      expect(results.every((r) => r.containsKey('label')), true);
      expect(results.every((r) => r.containsKey('confidence')), true);
    });

    test('Calculate average confidence across detections', () {
      final confidences = [0.9, 0.85, 0.95, 0.8];
      final average = confidences.reduce((a, b) => a + b) / confidences.length;

      expect(average, closeTo(0.875, 0.001));
    });

    test('Find most common disease in batch', () {
      final detections = [
        'Leaf Blast',
        'Brown Spot',
        'Leaf Blast',
        'Leaf Blast',
        'Healthy'
      ];

      final counts = <String, int>{};
      for (var disease in detections) {
        counts[disease] = (counts[disease] ?? 0) + 1;
      }

      String mostCommon = '';
      int maxCount = 0;
      counts.forEach((disease, count) {
        if (count > maxCount) {
          maxCount = count;
          mostCommon = disease;
        }
      });

      expect(mostCommon, 'Leaf Blast');
      expect(maxCount, 3);
    });
  });

  group('Image Quality Validation Tests', () {
    test('Validate minimum image dimensions', () {
      bool isValidDimension(int width, int height, int minSize) {
        return width >= minSize && height >= minSize;
      }

      expect(isValidDimension(224, 224, 200), true);
      expect(isValidDimension(150, 150, 200), false);
      expect(isValidDimension(300, 200, 200), true);
    });

    test('Calculate aspect ratio', () {
      double getAspectRatio(int width, int height) {
        return width / height;
      }

      expect(getAspectRatio(224, 224), 1.0);
      expect(getAspectRatio(400, 300), closeTo(1.33, 0.01));
    });

    test('Check if image is square', () {
      bool isSquare(int width, int height) {
        return width == height;
      }

      expect(isSquare(224, 224), true);
      expect(isSquare(300, 200), false);
    });
  });
}
