import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_localization/flutter_localization.dart';
import '../services/products_service.dart';
import '../services/disease_records_service.dart';
import '../services/model_manager_service.dart';
import '../config/supabase_config.dart';
import 'marketplace_screen.dart';
import '../l10n/app_locale.dart';

class DetectScreen extends StatefulWidget {
  const DetectScreen({super.key});

  @override
  State<DetectScreen> createState() => _DetectScreenState();
}

class _DetectScreenState extends State<DetectScreen> {
  File? _image;
  final picker = ImagePicker();
  final ProductsService _productsService = ProductsService();
  final DiseaseRecordsService _diseaseRecordsService = DiseaseRecordsService();
  bool _isAnalyzing = false;
  bool _isModelLoaded = false;
  Map<String, dynamic>? _result;
  List<String> _diseaseClasses = [];
  Interpreter? _interpreter;
  List<Map<String, dynamic>> _recommendedProducts = [];
  String _normalizationMethod = 'method1';
  String _selectedModel = 'assets/model/model.tflite';

  // Model configuration - UPDATED TO NEW MODEL
  static const String _modelPath = 'assets/model/model.tflite';
  static const String _labelsPath = 'assets/model/labels.txt';

  @override
  void initState() {
    super.initState();
    print('🚀 Detect Screen initialized - Loading AI model...');
    _loadSettings();
    _loadModel();
  }
  
  Future<void> _loadSettings() async {
    try {
      final method = await ModelManagerService.getNormalizationMethod();
      final model = await ModelManagerService.getSelectedModel();
      setState(() {
        _normalizationMethod = method;
        _selectedModel = model;
      });
      print('✅ Loaded settings - Method: $method, Model: $model');
    } catch (e) {
      print('⚠️ Error loading settings: $e');
    }
  }

  Future<void> _loadModel() async {
    try {
      print('� Loading AI model and labels...');
      
      // Load labels from assets
      await _loadLabels();
      
      // Load TensorFlow Lite model
      await _loadTFLiteModel();
      
      setState(() {
        _isModelLoaded = true;
      });
      
      print('✅ AI model loaded successfully!');
      _printModelInfo();
      
    } catch (e) {
      print('❌ Error loading model: $e');
      setState(() {
        _isModelLoaded = false;
      });
      
      _showErrorDialog(
        'Failed to load AI model.\n\n'
        'Please ensure:\n'
        '• model_unquant.tflite is in assets/model/\n'
        '• labels.txt is in assets/model/\n'
        '• Try restarting the app\n\n'
        'Technical error: $e'
      );
    }
  }

  Future<void> _loadLabels() async {
    try {
      print('📋 Loading labels from $_labelsPath...');
      final labelsData = await rootBundle.loadString(_labelsPath);
      _diseaseClasses = labelsData
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.trim())
          .toList();
      print('✅ Loaded ${_diseaseClasses.length} disease classes: $_diseaseClasses');
    } catch (e) {
      print('⚠️ Labels file not found, using default classes: $e');
      _diseaseClasses = [
        'Brown Planthopper',
        'Brown Spot',
        'Healthy',
        'Leaf Blast',
        'Leaf Scald',
        'Rice Leafroller',
        'Rice Yellow Stem Borer',
        'Sheath Blight',
      ];
    }
  }

  Future<void> _loadTFLiteModel() async {
    try {
      print('🤖 Loading TensorFlow Lite model from $_modelPath...');
      
      // Try multiple loading methods for better compatibility
      try {
        // Method 1: Standard asset loading
        _interpreter = await Interpreter.fromAsset(_modelPath);
        print('✅ Model loaded using standard asset loading');
      } catch (e1) {
        print('⚠️ Standard loading failed: $e1');
        
        try {
          // Method 2: Loading with interpreter options
          final options = InterpreterOptions();
          options.threads = 1;
          _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
          print('✅ Model loaded using interpreter options');
        } catch (e2) {
          print('⚠️ Options loading failed: $e2');
          
          // Method 3: Loading from buffer
          final modelData = await rootBundle.load(_modelPath);
          final modelBytes = modelData.buffer.asUint8List();
          _interpreter = Interpreter.fromBuffer(modelBytes);
          print('✅ Model loaded from buffer');
        }
      }
      
      if (_interpreter == null) {
        throw Exception('Failed to initialize interpreter');
      }
    } catch (e) {
      print('❌ Failed to load TensorFlow Lite model: $e');
      throw Exception('TensorFlow Lite model loading failed: $e');
    }
  }

  void _printModelInfo() {
    if (_interpreter == null) return;
    
    try {
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();
      
      print('📊 Model Information:');
      print('   Input tensors: ${inputTensors.length}');
      print('   Output tensors: ${outputTensors.length}');
      
      if (inputTensors.isNotEmpty) {
        final inputTensor = inputTensors.first;
        print('   Input shape: ${inputTensor.shape}');
        print('   Input type: ${inputTensor.type}');
      }
      
      if (outputTensors.isNotEmpty) {
        final outputTensor = outputTensors.first;
        print('   Output shape: ${outputTensor.shape}');
        print('   Output type: ${outputTensor.type}');
      }
    } catch (e) {
      print('⚠️ Error getting model info: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _result = null; // Clear previous results
        });
        print('📸 Image selected: ${pickedFile.path}');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) {
      _showErrorDialog('Please select an image first');
      return;
    }

    if (!_isModelLoaded) {
      _showErrorDialog('AI model is not loaded yet. Please wait...');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    try {
      print('🔍 Starting AI disease detection...');
      
      // Validate interpreter
      if (_interpreter == null) {
        throw Exception('Interpreter is null');
      }
      
      // Load and preprocess the image
      final imageBytes = await _image!.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      print('📸 Original image: ${image.width}x${image.height}');
      
      // Get model input requirements
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();
      
      if (inputTensors.isEmpty || outputTensors.isEmpty) {
        throw Exception('Model has no input or output tensors');
      }
      
      final inputShape = inputTensors.first.shape;
      final outputShape = outputTensors.first.shape;
      
      print('📐 Input shape: $inputShape');
      print('📐 Output shape: $outputShape');
      
      // Validate input shape
      if (inputShape.length != 4) {
        throw Exception('Expected 4D input tensor [batch, height, width, channels], got: $inputShape');
      }
      
      // Extract dimensions [batch, height, width, channels]
      final batchSize = inputShape[0];
      final inputHeight = inputShape[1];
      final inputWidth = inputShape[2];
      final inputChannels = inputShape[3];
      final numClasses = outputShape.length > 1 ? outputShape[1] : outputShape[0];
      
      print('📐 Model expects: ${inputWidth}x${inputHeight}x$inputChannels');
      print('📐 Model outputs: $numClasses classes');
      
      // Resize image to model input size
      final resizedImage = img.copyResize(
        image,
        width: inputWidth,
        height: inputHeight,
        interpolation: img.Interpolation.linear,
      );
      
      print('🔧 Resized to: ${resizedImage.width}x${resizedImage.height}');
      
      // Convert image to input tensor format [1, h, w, 3]
      print('🔧 Using normalization method: $_normalizationMethod (${ModelManagerService.methodDescriptions[_normalizationMethod]})');
      final input = _imageToInputTensor(resizedImage, batchSize, inputHeight, inputWidth, inputChannels, _normalizationMethod);
      
      // Create output tensor
      var output = List.filled(batchSize * numClasses, 0.0).reshape([batchSize, numClasses]);
      
      print('🤖 Running inference...');
      print('📊 Input shape: ${input.length}x${input[0].length}x${input[0][0].length}x${input[0][0][0].length}');
      print('📊 Output shape: ${output.length}x${output[0].length}');
      
      // Run inference
      _interpreter!.run(input, output);
      
      // Get predictions from the first batch
      final predictions = output[0] as List<double>;
      print('📊 Raw predictions: $predictions');
      
      // Validate predictions
      if (predictions.isEmpty) {
        throw Exception('Model returned empty predictions');
      }
      
      // Apply softmax to get probabilities
      final probabilities = _applySoftmax(predictions);
      print('📊 Probabilities: $probabilities');
      
      // Find the class with highest probability
      double maxProb = 0.0;
      int maxIndex = 0;
      
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }
      
      // Get the predicted disease
      String diseaseName = maxIndex < _diseaseClasses.length 
          ? _diseaseClasses[maxIndex] 
          : 'Unknown (Index: $maxIndex)';
      
      print('🎯 Detected: $diseaseName (${(maxProb * 100).toStringAsFixed(1)}% accuracy)');
      
      // Check if accuracy is too low (below 15%)
      if (maxProb < 0.15) {
        print('⚠️ Low accuracy detected: ${(maxProb * 100).toStringAsFixed(1)}%');
        setState(() {
          _isAnalyzing = false;
        });
        
        _showErrorDialog(
          'Invalid Image or Low Quality\n\n'
          'The AI model cannot confidently analyze this image. '
          'This could be due to:\n\n'
          '• Poor image quality or lighting\n'
          '• Image is not a rice plant\n'
          '• Plant part is not clearly visible\n\n'
          'Please try again with:\n'
          '• Better lighting conditions\n'
          '• Clear focus on the rice plant\n'
          '• Close-up of affected leaves'
        );
        return;
      }
      
      // Create comprehensive result
      final aiResult = {
        'disease': diseaseName,
        'confidence': maxProb,
        'description': _getDiseaseDescription(diseaseName),
        'isHealthy': diseaseName.toLowerCase().contains('healthy'),
        'timestamp': DateTime.now().toIso8601String(),
        'allProbabilities': Map.fromIterables(
          _diseaseClasses.length == probabilities.length 
              ? _diseaseClasses 
              : List.generate(probabilities.length, (i) => 'Class_$i'),
          probabilities
        ),
      };

      // Fetch recommended products from database
      print('🛒 Fetching recommended products for: $diseaseName');
      final products = await _productsService.getProductsForDisease(diseaseName);
      
      setState(() {
        _result = aiResult;
        _recommendedProducts = products;
        _isAnalyzing = false;
      });
      
      print('✅ AI Analysis completed successfully');
      
      // Save detection to history (non-blocking)
      _saveDetectionToHistory(diseaseName, maxProb);
      print('✅ Found ${products.length} recommended products');
      
    } catch (e) {
      print('❌ Error during AI analysis: $e');
      setState(() {
        _isAnalyzing = false;
        _result = {
          'disease': 'Analysis Failed',
          'confidence': 0.0,
          'description': 'AI analysis failed: $e',
          'isHealthy': false,
        };
      });
    }
  }

  // Save detection to history with image upload
  Future<void> _saveDetectionToHistory(String diseaseName, double confidence) async {
    if (_image == null) return;
    
    try {
      print('💾 Saving detection to history...');
      
      // Upload image to Supabase Storage
      String? imageUrl;
      try {
        final supabase = SupabaseConfig.client;
        final fileName = 'detection_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = 'disease_detections/$fileName';
        
        print('📤 Uploading image to storage: $filePath');
        
        // Read image bytes
        final bytes = await _image!.readAsBytes();
        
        // Upload the file
        await supabase.storage
            .from('disease-images')
            .uploadBinary(
              filePath,
              bytes,
            );
        
        // Get public URL
        imageUrl = supabase.storage
            .from('disease-images')
            .getPublicUrl(filePath);
        
        print('✅ Image uploaded successfully: $imageUrl');
      } catch (e) {
        print('⚠️ Image upload failed (continuing without image): $e');
        // Continue saving detection even if image upload fails
      }
      
      // Determine severity based on confidence and disease type
      String severity;
      if (diseaseName.toLowerCase().contains('healthy')) {
        severity = 'healthy';
      } else if (confidence > 0.8) {
        severity = 'high';
      } else if (confidence > 0.5) {
        severity = 'medium';
      } else {
        severity = 'low';
      }
      
      // Save detection to database
      final result = await _diseaseRecordsService.addDetection(
        diseaseName: diseaseName,
        confidence: confidence,
        imageUrl: imageUrl,
        severity: severity,
        notes: 'Auto-detected using AI model',
      );
      
      if (result['success']) {
        print('✅ Detection saved to history');
      } else {
        print('❌ Failed to save detection: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error saving detection to history: $e');
    }
  }

  // Convert image to input tensor format
  List<List<List<List<double>>>> _imageToInputTensor(
    img.Image image, 
    int batchSize, 
    int height, 
    int width, 
    int channels,
    [String normalizationMethod = 'method1']
  ) {
    return List.generate(batchSize, (batch) {
      return List.generate(height, (y) {
        return List.generate(width, (x) {
          final pixel = image.getPixel(x, y);
          if (channels == 3) {
            // Apply selected normalization method
            switch (normalizationMethod) {
              case 'method1': // [0, 1] normalization
                return [
                  pixel.r / 255.0,
                  pixel.g / 255.0,
                  pixel.b / 255.0,
                ];
              case 'method2': // [-1, 1] normalization
                return [
                  (pixel.r - 127.5) / 127.5,
                  (pixel.g - 127.5) / 127.5,
                  (pixel.b - 127.5) / 127.5,
                ];
              case 'method3': // ImageNet normalization
                return [
                  (pixel.r / 255.0 - 0.485) / 0.229,
                  (pixel.g / 255.0 - 0.456) / 0.224,
                  (pixel.b / 255.0 - 0.406) / 0.225,
                ];
              default:
                return [
                  pixel.r / 255.0,
                  pixel.g / 255.0,
                  pixel.b / 255.0,
                ];
            }
          } else if (channels == 1) {
            // Grayscale format
            final gray = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255.0;
            return [gray];
          } else {
            throw Exception('Unsupported number of channels: $channels');
          }
        });
      });
    });
  }

  // Apply softmax activation to convert logits to probabilities
  List<double> _applySoftmax(List<double> logits) {
    // Find max value for numerical stability
    final maxLogit = logits.reduce(math.max);
    
    // Compute exponentials
    final expLogits = logits.map((x) => math.exp(x - maxLogit)).toList();
    
    // Compute sum of exponentials
    final sumExp = expLogits.reduce((a, b) => a + b);
    
    if (sumExp == 0) {
      throw Exception('Invalid model output - sum of exponentials is zero');
    }
    
    // Normalize to get probabilities
    return expLogits.map((x) => x / sumExp).toList();
  }

  String _getDiseaseDescription(String diseaseName) {
    final descriptions = {
      'Brown Planthopper': AppLocale.brownPlanthopperDesc.getString(context),
      'Brown Spot': AppLocale.brownSpotDesc.getString(context),
      'Healthy': AppLocale.healthyDesc.getString(context),
      'Leaf Blast': AppLocale.leafBlastDesc.getString(context),
      'Leaf Scald': AppLocale.leafScaldDesc.getString(context),
      'Rice Leafroller': AppLocale.riceLeafrollerDesc.getString(context),
      'Rice Yellow Stem Borer': AppLocale.riceYellowStemBorerDesc.getString(context),
      'Sheath Blight': AppLocale.sheathBlightDesc.getString(context),
    };
    
    return descriptions[diseaseName] ?? 'AI has detected this condition in your rice plant.';
  }

  String _getLocalizedDiseaseName(String diseaseName) {
    final names = {
      'Brown Planthopper': AppLocale.brownPlanthopper.getString(context),
      'Brown Spot': AppLocale.brownSpot.getString(context),
      'Healthy': AppLocale.healthyPlant.getString(context),
      'Leaf Blast': AppLocale.leafBlast.getString(context),
      'Leaf Scald': AppLocale.leafScald.getString(context),
      'Rice Leafroller': AppLocale.riceLeafroller.getString(context),
      'Rice Yellow Stem Borer': AppLocale.riceYellowStemBorer.getString(context),
      'Sheath Blight': AppLocale.sheathBlight.getString(context),
    };
    
    return names[diseaseName] ?? diseaseName;
  }

  String _getLocalizedCategory(String? category) {
    if (category == null) return 'Product';
    final categories = {
      'Fungicides': AppLocale.fungicides.getString(context),
      'Pesticides': AppLocale.pesticides.getString(context),
      'Fertilizers': AppLocale.fertilizers.getString(context),
      'Organic': AppLocale.organic.getString(context),
      'Seeds': AppLocale.seeds.getString(context),
      'Tools': AppLocale.tools.getString(context),
    };
    return categories[category] ?? category;
  }

  void _showProductDetails(Map<String, dynamic> product) {
    // Determine product icon based on category
    String getProductIcon(String? category) {
      switch(category) {
        case 'Fungicides': return '🍄';
        case 'Pesticides': return '🧪';
        case 'Fertilizers': return '🌱';
        case 'Organic': return '🌿';
        case 'Seeds': return '🌾';
        case 'Tools': return '🔧';
        default: return '📦';
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Text(
                getProductIcon(product['category']),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product['name'] ?? AppLocale.unknownProduct.getString(context),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                if (product['image_url'] != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product['image_url'],
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: product['category'] == 'Fertilizers' || product['category'] == 'Organic'
                        ? Colors.green.shade100 
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getLocalizedCategory(product['category']),
                    style: TextStyle(
                      color: product['category'] == 'Fertilizers' || product['category'] == 'Organic'
                          ? Colors.green.shade700 
                          : Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Description
                Text(
                  product['description'] ?? AppLocale.noDescriptionAvailable.getString(context),
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 12),
                
                // Effective Against Diseases
                if (product['diseases'] != null && (product['diseases'] as List).isNotEmpty) ...[
                  Text(
                    AppLocale.effectiveAgainst.getString(context),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: (product['diseases'] as List).map((disease) => Chip(
                      label: Text(
                        _getLocalizedDiseaseName(disease.toString()),
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.orange.shade100,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Price and Stock
                Row(
                  children: [
                    Icon(Icons.sell, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      AppLocale.price.getString(context),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      'RM ${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      (product['in_stock'] ?? false) ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: (product['in_stock'] ?? false) ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (product['in_stock'] ?? false) ? AppLocale.inStock.getString(context) : AppLocale.outOfStock.getString(context),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: (product['in_stock'] ?? false) ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocale.close.getString(context)),
            ),
            if (product['in_stock'] ?? false)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _addToCart(product);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocale.addToCart.getString(context)),
              ),
          ],
        );
      },
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${product['name']} ${AppLocale.addedToCart.getString(context)}'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: AppLocale.viewCart.getString(context).toUpperCase(),
          textColor: Colors.white,
          onPressed: () {
            // TODO: Navigate to cart screen
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up TensorFlow Lite resources
    _interpreter?.close();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocale.error.getString(context)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocale.ok.getString(context)),
            ),
          ],
        );
      },
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocale.selectImageSource.getString(context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(AppLocale.camera.getString(context)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocale.gallery.getString(context)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade700,
              Colors.green.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocale.paddyAIDetection.getString(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isModelLoaded ? '🤖 ${AppLocale.aiReady.getString(context)}' : '⏳ ${AppLocale.loadingAIModel.getString(context)}',  
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.tune, color: Colors.white),
                tooltip: 'Normalization Method',
                onSelected: (value) async {
                  await ModelManagerService.setNormalizationMethod(value);
                  setState(() => _normalizationMethod = value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Method changed to: ${ModelManagerService.methodDescriptions[value]}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  print('✅ Normalization method changed to: $value');
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'method1',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_normalizationMethod == 'method1' ? '✓ Method 1' : 'Method 1'),
                        const Text('[0, 1] Div by 255', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'method2',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_normalizationMethod == 'method2' ? '✓ Method 2' : 'Method 2'),
                        const Text('[-1, 1] (x-127.5)/127.5', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'method3',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_normalizationMethod == 'method3' ? '✓ Method 3' : 'Method 3'),
                        const Text('ImageNet Norm', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: () => _showInfoDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Card
          _buildStatusCard(),
          
          const SizedBox(height: 20),
          
          // Image Display Section
          _buildImageSection(),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          _buildActionButtons(),
          
          const SizedBox(height: 20),
          
          // Results Section
          if (_result != null) _buildResultsSection(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isModelLoaded ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isModelLoaded ? Icons.check_circle : Icons.hourglass_empty,
              color: _isModelLoaded ? Colors.green.shade700 : Colors.orange.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isModelLoaded ? AppLocale.aiModelReady.getString(context) : AppLocale.loadingAIModel.getString(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isModelLoaded 
                      ? AppLocale.readyToAnalyze.getString(context)
                      : AppLocale.pleaseWaitAI.getString(context),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (_isAnalyzing)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _image == null ? _buildPlaceholder() : _buildImageDisplay(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showImageSourceDialog,
            icon: const Icon(Icons.add_a_photo),
            label: Text(AppLocale.selectImage.getString(context)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _image != null && !_isAnalyzing && _isModelLoaded
                ? _analyzeImage 
                : null,
            child: _isAnalyzing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(_isAnalyzing 
                    ? AppLocale.analyzing.getString(context)
                    : !_isModelLoaded 
                        ? AppLocale.loadingAIModel.getString(context)
                        : AppLocale.analyzeWithAI.getString(context)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
          ),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(AppLocale.aboutPaddyAI.getString(context)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocale.aboutPaddyAIDesc.getString(context),
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocale.features.getString(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(AppLocale.featureAIPowered.getString(context)),
              Text(AppLocale.featureTreatment.getString(context)),
              Text(AppLocale.featureMarketplace.getString(context)),
              Text(AppLocale.featureRealTime.getString(context)),
              const SizedBox(height: 12),
              Text(
                AppLocale.aboutPaddyAIFooter.getString(context),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocale.gotIt.getString(context)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade50,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                size: 48,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocale.noImageSelected.getString(context),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocale.takePhotoOrSelect.getString(context),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocale.tipClearPhotos.getString(context),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            _image!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // Overlay with image info
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocale.imageReady.getString(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Replace image button
        Positioned(
          bottom: 12,
          right: 12,
          child: FloatingActionButton.small(
            onPressed: _showImageSourceDialog,
            backgroundColor: Colors.white,
            foregroundColor: Colors.green.shade700,
            elevation: 4,
            child: const Icon(Icons.edit),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analysis Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.science,
                  color: Colors.green.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocale.aiAnalysisResults.getString(context),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Disease Detection Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _result!['isHealthy'] ? Colors.green.shade50 : Colors.orange.shade50,
                  _result!['isHealthy'] ? Colors.green.shade100 : Colors.orange.shade100,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _result!['isHealthy'] ? Colors.green.shade200 : Colors.orange.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _result!['isHealthy'] ? '🌱' : '🦠',
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getLocalizedDiseaseName(_result!['disease']),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _result!['description'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recommendations Section
          _buildRecommendationsSection(),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    // Use products from database instead of hardcoded list
    if (_recommendedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_cart,
                color: Colors.blue.shade700,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _result!['isHealthy'] ? AppLocale.recommendedProducts.getString(context) : AppLocale.treatmentProducts.getString(context),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendedProducts.length,
            itemBuilder: (context, index) {
              final product = _recommendedProducts[index];
              return Container(
                width: 260,
                margin: const EdgeInsets.only(right: 10),
                child: _buildProductCard(product),
              );
            },
          ),
        ),
        
        const SizedBox(height: 12),
        
        // View All Products Button
        Center(
          child: OutlinedButton.icon(
            onPressed: () => _showAllProducts(_recommendedProducts),
            icon: const Icon(Icons.store, size: 18),
            label: Text(AppLocale.viewAllProducts.getString(context), style: const TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade700,
              side: BorderSide(color: Colors.green.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    // Determine product icon/emoji based on category
    String getProductIcon(String? category) {
      switch(category) {
        case 'Fungicides': return '🍄';
        case 'Pesticides': return '🧪';
        case 'Fertilizers': return '🌱';
        case 'Organic': return '🌿';
        case 'Seeds': return '🌾';
        case 'Tools': return '🔧';
        default: return '📦';
      }
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Header with image if available
              if (product['image_url'] != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    product['image_url'],
                    height: 70,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 70,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Text(
                          getProductIcon(product['category']),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              
              // Product Name
              Row(
                children: [
                  if (product['image_url'] == null) ...[
                    Text(
                      getProductIcon(product['category']),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      product['name'] ?? AppLocale.unknownProduct.getString(context),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 6),
              
              // Product Category Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: product['category'] == 'Fertilizers' || product['category'] == 'Organic'
                      ? Colors.green.shade100 
                      : product['category'] == 'Fungicides'
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getLocalizedCategory(product['category']),
                  style: TextStyle(
                    color: product['category'] == 'Fertilizers' || product['category'] == 'Organic'
                        ? Colors.green.shade700 
                        : product['category'] == 'Fungicides'
                            ? Colors.orange.shade700
                            : Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                  ),
                ),
              ),
              
              const SizedBox(height: 6),
              
              // Description
              Text(
                product['description'] ?? AppLocale.noDescriptionAvailable.getString(context),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              // Price and Stock Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'RM ${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: (product['in_stock'] ?? false) ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (product['in_stock'] ?? false) ? AppLocale.inStock.getString(context) : AppLocale.out.getString(context),
                      style: TextStyle(
                        fontSize: 9,
                        color: (product['in_stock'] ?? false) ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllProducts(List<Map<String, dynamic>> products) {
    // Navigate to marketplace screen with disease filter
    final diseaseName = _result?['disease'] as String?;
    if (diseaseName != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarketplaceScreen(diseaseFilter: diseaseName),
        ),
      );
    }
  }
}
