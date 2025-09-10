# TensorFlow Lite Flutter Implementation

This implementation provides a complete TensorFlow Lite classifier for Flutter using the `tflite_flutter` plugin.

## Files Created

1. **`lib/services/tflite_classifier.dart`** - Main classifier class
2. **`lib/screens/image_classifier_screen.dart`** - Complete UI example
3. **`lib/examples/example_integration.dart`** - Integration guide

## Features

- ✅ Loads TensorFlow Lite model from `assets/model/model_unquant.tflite`
- ✅ Loads labels from `assets/model/labels.txt`
- ✅ Initializes Interpreter with error handling
- ✅ Prints input/output tensor shapes
- ✅ Provides `classifyImage(File image)` function
- ✅ Resizes images to 224x224 automatically
- ✅ Runs inference and maps output to labels
- ✅ Returns comprehensive classification results
- ✅ Handles multiple loading methods for compatibility
- ✅ Applies softmax for probability distribution
- ✅ Includes top-N predictions functionality

## Usage

### Basic Usage

```dart
// 1. Create classifier instance
final TFLiteClassifier classifier = TFLiteClassifier();

// 2. Initialize the model
await classifier.initialize();

// 3. Classify an image
final File imageFile = File('path/to/image.jpg');
final ClassificationResult result = await classifier.classifyImage(imageFile);

// 4. Use the results
print('Predicted: ${result.label}');
print('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');

// 5. Get top 3 predictions
final top3 = result.getTopPredictions(3);
for (final prediction in top3) {
  print('${prediction.key}: ${(prediction.value * 100).toStringAsFixed(1)}%');
}

// 6. Clean up
classifier.dispose();
```

### Integration with Existing Code

To integrate with your existing `detect_screen.dart`:

```dart
class _DetectScreenState extends State<DetectScreen> {
  final TFLiteClassifier _classifier = TFLiteClassifier();
  bool _isModelLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
  }

  Future<void> _initializeClassifier() async {
    final success = await _classifier.initialize();
    setState(() {
      _isModelLoaded = success;
    });
  }

  Future<void> _analyzeImage() async {
    if (_image == null || !_isModelLoaded) return;
    
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      final result = await _classifier.classifyImage(_image!);
      setState(() {
        _result = {
          'disease': result.label,
          'confidence': result.confidence,
          'description': _getDiseaseDescription(result.label),
          'isHealthy': result.label.toLowerCase().contains('healthy'),
          'timestamp': result.timestamp.toIso8601String(),
          'allProbabilities': result.allProbabilities,
        };
        _isAnalyzing = false;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }
}
```

## Model Requirements

### Model File
- **Path**: `assets/model/model_unquant.tflite`
- **Input**: [1, 224, 224, 3] (RGB image, normalized to 0-1)
- **Output**: [1, num_classes] (logits or probabilities)

### Labels File
- **Path**: `assets/model/labels.txt`
- **Format**: One label per line
- **Example**:
  ```
  Brown Planthopper
  Brown Spot
  Healthy
  Leaf Blast
  Leaf Scald
  Rice Leafroller
  Rice Yellow Stem Borer
  Sheath Blight
  ```

## Asset Configuration

Make sure your `pubspec.yaml` includes the assets:

```yaml
flutter:
  assets:
    - assets/model/model_unquant.tflite
    - assets/model/labels.txt
```

## Dependencies

Required dependencies in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  tflite_flutter: ^0.11.0
  image: ^4.5.4
  image_picker: ^1.1.0  # For image selection (optional)
```

## Error Handling

The implementation includes comprehensive error handling:

- Multiple model loading methods for compatibility
- Input validation
- Tensor shape verification
- Softmax application for probability normalization
- Detailed error messages and debugging information

## API Reference

### TFLiteClassifier

#### Methods

- `Future<bool> initialize()` - Initialize the model and labels
- `Future<ClassificationResult> classifyImage(File imageFile)` - Classify an image
- `List<String> get labels` - Get the list of loaded labels
- `bool get isModelLoaded` - Check if model is ready
- `void dispose()` - Clean up resources

### ClassificationResult

#### Properties

- `String label` - Predicted class label
- `double confidence` - Confidence score (0.0 to 1.0)
- `Map<String, double> allProbabilities` - All class probabilities
- `DateTime timestamp` - Classification timestamp

#### Methods

- `List<MapEntry<String, double>> getTopPredictions(int n)` - Get top N predictions
- `Map<String, dynamic> toMap()` - Convert to map for serialization

## Troubleshooting

### Model Loading Issues

1. **File not found**: Ensure the `.tflite` file is in `assets/model/`
2. **Asset not declared**: Check `pubspec.yaml` assets section
3. **Invalid model**: Verify the model is a valid TensorFlow Lite file
4. **Dependencies**: Run `flutter clean && flutter pub get`

### Common Errors

- **"Interpreter is null"**: Model failed to load, check file path and validity
- **"Failed to decode image"**: Invalid image file format
- **"Tensor shape mismatch"**: Model expects different input dimensions
- **"Index out of range"**: Labels file doesn't match model output classes

## Performance Tips

1. **Model Optimization**: Use quantized models for better performance
2. **Image Preprocessing**: Resize images before passing to classifier
3. **Memory Management**: Always call `dispose()` to free resources
4. **Threading**: Model loading and inference run on separate threads

## Complete Example

See `lib/screens/image_classifier_screen.dart` for a complete working example with UI.

## Testing

To test the implementation:

1. Add a test model and labels to `assets/model/`
2. Run the app and use the ImageClassifierScreen
3. Select an image and tap "Classify"
4. Check console output for detailed debugging information

## Console Output

The implementation provides detailed console logging:

```
🚀 Initializing TFLite Classifier...
📋 Loading labels from assets/model/labels.txt...
✅ Loaded 8 labels: [Brown Planthopper, Brown Spot, ...]
🤖 Loading TensorFlow Lite model from assets/model/model_unquant.tflite...
✅ Model loaded using standard asset loading
📊 Model Information:
   Input tensors: 1
   Output tensors: 1
   Input shape: [1, 224, 224, 3]
   Input type: TfLiteType.float32
   Output shape: [1, 8]
   Output type: TfLiteType.float32
✅ TFLite Classifier initialized successfully
🔍 Classifying image: /path/to/image.jpg
📸 Original image: 1024x768
🔧 Resized to: 224x224
🤖 Running inference...
📊 Raw predictions: [0.1, 0.2, 0.8, 0.1, ...]
🎯 Prediction: Healthy (85.2% confidence)
```
