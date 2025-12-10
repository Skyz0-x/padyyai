import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/disease_detection_service.dart';

/// Screen to test different normalization methods and find the correct one
class NormalizationTestScreen extends StatefulWidget {
  const NormalizationTestScreen({super.key});

  @override
  State<NormalizationTestScreen> createState() => _NormalizationTestScreenState();
}

class _NormalizationTestScreenState extends State<NormalizationTestScreen> {
  final _service = DiseaseDetectionService();
  File? _image;
  bool _isAnalyzing = false;
  Map<String, Map<String, dynamic>> _results = {};

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _results = {};
      });
    }
  }

  Future<void> _testAllMethods() async {
    if (_image == null) return;
    
    setState(() {
      _isAnalyzing = true;
      _results = {};
    });

    try {
      // Test Method 1: [0, 1]
      print('\n${'=' * 70}');
      print('TESTING METHOD 1: [0, 1] Normalization');
      print('=' * 70);
      final result1 = await _service.classify(_image!, normalizationMethod: 'method1');
      
      // Test Method 2: [-1, 1]
      print('\n${'=' * 70}');
      print('TESTING METHOD 2: [-1, 1] Normalization');
      print('=' * 70);
      final result2 = await _service.classify(_image!, normalizationMethod: 'method2');
      
      // Test Method 3: ImageNet
      print('\n${'=' * 70}');
      print('TESTING METHOD 3: ImageNet Normalization');
      print('=' * 70);
      final result3 = await _service.classify(_image!, normalizationMethod: 'method3');
      
      setState(() {
        _results = {
          'method1': result1,
          'method2': result2,
          'method3': result3,
        };
      });
      
      print('\n${'=' * 70}');
      print('✅ COMPARISON COMPLETE - Check results above');
      print('${'=' * 70}\n');
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Normalization Test'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.science, size: 48, color: Colors.blue),
                    const SizedBox(height: 8),
                    const Text(
                      'Test Normalization Methods',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This tool tests 3 different normalization methods to find which one works best with your model.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            if (_image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],
            
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Select Test Image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: (_image == null || _isAnalyzing) ? null : _testAllMethods,
              icon: _isAnalyzing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isAnalyzing ? 'Testing...' : 'Test All Methods'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            
            if (_results.isNotEmpty) ...[
              const Text(
                'Results Comparison:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              _buildResultCard(
                'Method 1: [0, 1]',
                'Divide by 255',
                _results['method1']!,
                Colors.blue,
              ),
              _buildResultCard(
                'Method 2: [-1, 1]',
                '(x - 127.5) / 127.5',
                _results['method2']!,
                Colors.orange,
              ),
              _buildResultCard(
                'Method 3: ImageNet',
                'Mean/Std normalization',
                _results['method3']!,
                Colors.purple,
              ),
              
              const SizedBox(height: 16),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'How to Choose:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Look for the HIGHEST confidence score\n'
                        '2. Check if the prediction makes sense\n'
                        '3. Test with 3-5 different images\n'
                        '4. Use the method that consistently gives best results',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String formula, Map<String, dynamic> result, Color color) {
    final confidence = (result['confidence'] as double) * 100;
    final label = result['label'] as String;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: color,
                        ),
                      ),
                      Text(
                        formula,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${confidence.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Prediction: $label',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
