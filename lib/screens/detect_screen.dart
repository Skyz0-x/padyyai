import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:math' as math;

class DetectScreen extends StatefulWidget {
  const DetectScreen({super.key});

  @override
  State<DetectScreen> createState() => _DetectScreenState();
}

class _DetectScreenState extends State<DetectScreen> {
  File? _image;
  final picker = ImagePicker();
  bool _isAnalyzing = false;
  bool _isModelLoaded = false;
  Map<String, dynamic>? _result;
  List<String> _diseaseClasses = [];
  Interpreter? _interpreter;

  // Model configuration
  static const String _modelPath = 'assets/model/model_unquant.tflite';
  static const String _labelsPath = 'assets/model/labels.txt';

  @override
  void initState() {
    super.initState();
    print('🚀 Detect Screen initialized - Loading AI model...');
    _loadModel();
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
      
      print('📐 Model expects: ${inputWidth}x${inputHeight}x${inputChannels}');
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
      final input = _imageToInputTensor(resizedImage, batchSize, inputHeight, inputWidth, inputChannels);
      
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

      setState(() {
        _result = aiResult;
        _isAnalyzing = false;
      });
      
      print('✅ AI Analysis completed successfully');
      
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

  // Convert image to input tensor format
  List<List<List<List<double>>>> _imageToInputTensor(
    img.Image image, 
    int batchSize, 
    int height, 
    int width, 
    int channels
  ) {
    return List.generate(batchSize, (batch) {
      return List.generate(height, (y) {
        return List.generate(width, (x) {
          final pixel = image.getPixel(x, y);
          if (channels == 3) {
            // RGB format - normalize to [0, 1]
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
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
      'Brown Planthopper': 'Serious insect pest that feeds on rice plants by sucking plant juices, causing yellowing and stunting.',
      'Brown Spot': 'Fungal disease caused by Bipolaris oryzae, appears as oval brown spots on leaves.',
      'Healthy': 'The rice plant appears healthy with no visible signs of disease or pest damage.',
      'Leaf Blast': 'Fungal disease caused by Magnaporthe oryzae, creates diamond-shaped lesions.',
      'Leaf Scald': 'Caused by Monographella albescens, creates whitish lesions with reddish-brown borders.',
      'Rice Leafroller': 'Larvae fold and roll rice leaves, feeding inside and reducing photosynthesis.',
      'Rice Yellow Stem Borer': 'Larvae bore into rice stems, causing deadhearts and whiteheads.',
      'Sheath Blight': 'Fungal disease caused by Rhizoctonia solani, creates irregular lesions on leaf sheaths.',
    };
    
    return descriptions[diseaseName] ?? 'AI has detected this condition in your rice plant.';
  }

  List<Map<String, dynamic>> _getRecommendedProducts(String diseaseName) {
    final recommendations = {
      'Brown Planthopper': [
        {
          'name': 'Imidacloprid 17.8% SL',
          'type': 'Pesticide',
          'price': '\$25.99',
          'rating': 4.5,
          'description': 'Systemic insecticide effective against brown planthopper',
          'dosage': '2ml per liter of water',
          'icon': '🧪',
        },
        {
          'name': 'Thiamethoxam 25% WG',
          'type': 'Pesticide',
          'price': '\$32.50',
          'rating': 4.7,
          'description': 'Long-lasting control of sucking pests',
          'dosage': '0.5g per liter of water',
          'icon': '🧪',
        },
      ],
      'Brown Spot': [
        {
          'name': 'Propiconazole 25% EC',
          'type': 'Fungicide',
          'price': '\$28.99',
          'rating': 4.6,
          'description': 'Effective fungicide for brown spot control',
          'dosage': '1ml per liter of water',
          'icon': '🍄',
        },
        {
          'name': 'Tricyclazole 75% WP',
          'type': 'Fungicide',
          'price': '\$24.75',
          'rating': 4.4,
          'description': 'Preventive and curative fungicide',
          'dosage': '0.6g per liter of water',
          'icon': '🍄',
        },
      ],
      'Leaf Blast': [
        {
          'name': 'Tricyclazole 75% WP',
          'type': 'Fungicide',
          'price': '\$24.75',
          'rating': 4.4,
          'description': 'Specialized treatment for blast diseases',
          'dosage': '0.6g per liter of water',
          'icon': '🍄',
        },
        {
          'name': 'Carbendazim 50% WP',
          'type': 'Fungicide',
          'price': '\$22.99',
          'rating': 4.3,
          'description': 'Broad spectrum fungicide',
          'dosage': '1g per liter of water',
          'icon': '🍄',
        },
      ],
      'Leaf Scald': [
        {
          'name': 'Mancozeb 75% WP',
          'type': 'Fungicide',
          'price': '\$19.99',
          'rating': 4.2,
          'description': 'Contact fungicide for leaf diseases',
          'dosage': '2g per liter of water',
          'icon': '🍄',
        },
        {
          'name': 'Copper Oxychloride 50% WP',
          'type': 'Fungicide',
          'price': '\$18.50',
          'rating': 4.1,
          'description': 'Protective fungicide with copper',
          'dosage': '3g per liter of water',
          'icon': '🍄',
        },
      ],
      'Rice Leafroller': [
        {
          'name': 'Chlorantraniliprole 18.5% SC',
          'type': 'Pesticide',
          'price': '\$35.99',
          'rating': 4.8,
          'description': 'Advanced insecticide for lepidopteran pests',
          'dosage': '0.5ml per liter of water',
          'icon': '🧪',
        },
        {
          'name': 'Cartap Hydrochloride 4% G',
          'type': 'Pesticide',
          'price': '\$21.99',
          'rating': 4.3,
          'description': 'Granular insecticide for stem borers',
          'dosage': '25kg per hectare',
          'icon': '🧪',
        },
      ],
      'Rice Yellow Stem Borer': [
        {
          'name': 'Cartap Hydrochloride 4% G',
          'type': 'Pesticide',
          'price': '\$21.99',
          'rating': 4.3,
          'description': 'Effective against stem borers',
          'dosage': '25kg per hectare',
          'icon': '🧪',
        },
        {
          'name': 'Fipronil 5% SC',
          'type': 'Pesticide',
          'price': '\$29.50',
          'rating': 4.5,
          'description': 'Systemic insecticide for borer control',
          'dosage': '2ml per liter of water',
          'icon': '🧪',
        },
      ],
      'Sheath Blight': [
        {
          'name': 'Hexaconazole 5% SC',
          'type': 'Fungicide',
          'price': '\$26.99',
          'rating': 4.5,
          'description': 'Triazole fungicide for sheath blight',
          'dosage': '2ml per liter of water',
          'icon': '🍄',
        },
        {
          'name': 'Validamycin 3% L',
          'type': 'Fungicide',
          'price': '\$31.99',
          'rating': 4.6,
          'description': 'Biological fungicide for soil-borne diseases',
          'dosage': '2.5ml per liter of water',
          'icon': '🍄',
        },
      ],
      'Healthy': [
        {
          'name': 'NPK 20:20:20 Water Soluble',
          'type': 'Biofertilizer',
          'price': '\$15.99',
          'rating': 4.4,
          'description': 'Balanced nutrition for healthy rice growth',
          'dosage': '5g per liter of water',
          'icon': '🌱',
        },
        {
          'name': 'Seaweed Extract Liquid',
          'type': 'Biofertilizer',
          'price': '\$18.75',
          'rating': 4.6,
          'description': 'Natural growth booster and stress reliever',
          'dosage': '3ml per liter of water',
          'icon': '🌱',
        },
        {
          'name': 'Humic Acid 98% Granules',
          'type': 'Biofertilizer',
          'price': '\$22.50',
          'rating': 4.7,
          'description': 'Improves soil health and nutrient uptake',
          'dosage': '2g per liter of water',
          'icon': '🌱',
        },
      ],
    };
    
    return recommendations[diseaseName] ?? [];
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Text(
                product['icon'],
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product['name'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product['type'] == 'Biofertilizer' 
                      ? Colors.green.shade100 
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product['type'],
                  style: TextStyle(
                    color: product['type'] == 'Biofertilizer' 
                        ? Colors.green.shade700 
                        : Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product['description'],
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.medication, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Dosage: ${product['dosage']}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${product['rating']}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    product['price'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showOrderDialog(product);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Order Now'),
            ),
          ],
        );
      },
    );
  }

  void _showOrderDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Order Confirmation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shopping_cart,
                size: 48,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                'Add ${product['name']} to cart?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                product['price'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product['name']} added to cart!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add to Cart'),
            ),
          ],
        );
      },
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
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
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
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PaddyAI Detection',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              _isModelLoaded ? '🤖 AI Ready' : '⏳ Loading AI...',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
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
          child: SingleChildScrollView(
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
          ),
        ),
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
                  _isModelLoaded ? 'AI Model Ready' : 'Loading AI Model...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isModelLoaded 
                      ? 'Ready to analyze rice plant diseases'
                      : 'Please wait while we prepare the AI...',
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
            label: const Text('Select Image'),
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
          child: ElevatedButton.icon(
            onPressed: _image != null && !_isAnalyzing && _isModelLoaded
                ? _analyzeImage 
                : null,
            icon: _isAnalyzing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.analytics),
            label: Text(_isAnalyzing 
                ? 'Analyzing...' 
                : !_isModelLoaded 
                    ? 'Loading AI...'
                    : 'Analyze with AI'),
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
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text('About PaddyAI'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PaddyAI uses advanced machine learning to detect rice plant diseases and pests.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• AI-powered disease detection'),
              Text('• Treatment recommendations'),
              Text('• Marketplace integration'),
              Text('• Real-time analysis'),
              SizedBox(height: 12),
              Text(
                'Simply take a photo of your rice plant and let our AI provide instant diagnosis and treatment suggestions!',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it!'),
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
              'No image selected',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo or select from gallery\nto start AI analysis',
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
                    'Tip: Use clear, well-lit photos for best results',
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
                const Text(
                  'Image Ready',
                  style: TextStyle(
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
                  Icons.analytics,
                  color: Colors.green.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Analysis Results',
                style: TextStyle(
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
            padding: const EdgeInsets.all(16),
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
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _result!['disease'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _result!['description'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Recommendations Section
          _buildRecommendationsSection(),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final recommendations = _getRecommendedProducts(_result!['disease']);
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_cart,
                color: Colors.blue.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _result!['isHealthy'] ? 'Recommended Biofertilizers' : 'Recommended Treatment',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Container(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final product = recommendations[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                child: _buildProductCard(product),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // View All Products Button
        Center(
          child: OutlinedButton.icon(
            onPressed: () => _showAllProducts(recommendations),
            icon: const Icon(Icons.store),
            label: const Text('View All Products'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade700,
              side: BorderSide(color: Colors.green.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Header
              Row(
                children: [
                  Text(
                    product['icon'],
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Product Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product['type'] == 'Biofertilizer' 
                      ? Colors.green.shade100 
                      : product['type'] == 'Fungicide'
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product['type'],
                  style: TextStyle(
                    color: product['type'] == 'Biofertilizer' 
                        ? Colors.green.shade700 
                        : product['type'] == 'Fungicide'
                            ? Colors.orange.shade700
                            : Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Description
              Text(
                product['description'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              // Price and Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product['price'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${product['rating']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('All Recommended Products'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: product['type'] == 'Biofertilizer' 
                          ? Colors.green.shade100 
                          : Colors.blue.shade100,
                      child: Text(
                        product['icon'],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Text(
                      product['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product['description']),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              product['price'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            Text(' ${product['rating']}'),
                          ],
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showProductDetails(product);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 36),
                      ),
                      child: const Text('View'),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
