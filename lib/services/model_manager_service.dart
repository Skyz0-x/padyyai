import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage AI model selection and normalization methods
class ModelManagerService {
  static const String _modelKey = 'selected_ai_model';
  static const String _normalizationKey = 'normalization_method';

  // Available models
  static const List<String> availableModels = [
    'assets/model/model.tflite',
    'assets/model/model_unquant.tflite',
    'assets/model/modelV2.tflite',
  ];

  // Normalization methods
  static const List<String> normalizationMethods = [
    'method1', // [0, 1] normalization
    'method2', // [-1, 1] normalization
    'method3', // ImageNet normalization
  ];

  static const Map<String, String> methodDescriptions = {
    'method1': '[0, 1] - Divide by 255',
    'method2': '[-1, 1] - (x - 127.5) / 127.5',
    'method3': 'ImageNet - Mean/Std Norm',
  };

  /// Get the currently selected AI model
  static Future<String> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelKey) ?? availableModels[0];
  }

  /// Set the AI model
  static Future<bool> setSelectedModel(String modelPath) async {
    if (!availableModels.contains(modelPath)) {
      throw Exception('Invalid model path: $modelPath');
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_modelKey, modelPath);
  }

  /// Get the currently selected normalization method
  static Future<String> getNormalizationMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_normalizationKey) ?? 'method1';
  }

  /// Set the normalization method
  static Future<bool> setNormalizationMethod(String method) async {
    if (!normalizationMethods.contains(method)) {
      throw Exception('Invalid normalization method: $method');
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_normalizationKey, method);
  }

  /// Get model display name from path
  static String getModelDisplayName(String modelPath) {
    if (modelPath.contains('modelV2')) {
      return 'Model v2';
    }
    if (modelPath.contains('model.tflite')) {
      return 'Model v1';
    } else if (modelPath.contains('model_unquant.tflite')) {
      return 'Model Unquantized';
    }
    return 'Unknown Model';
  }

  /// Get labels path for a given model
  static String getLabelsPathForModel(String modelPath) {
    return modelPath.contains('modelV2')
        ? 'assets/model/labelsV2.txt'
        : 'assets/model/labels.txt';
  }
}
