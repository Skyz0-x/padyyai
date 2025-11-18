import 'package:flutter/material.dart';
import '../services/disease_records_service.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class DetectHistoryScreen extends StatefulWidget {
  const DetectHistoryScreen({super.key});

  @override
  State<DetectHistoryScreen> createState() => _DetectHistoryScreenState();
}

class _DetectHistoryScreenState extends State<DetectHistoryScreen> {
  final DiseaseRecordsService _diseaseService = DiseaseRecordsService();
  
  List<Map<String, dynamic>> _allDetections = [];
  bool _isLoading = true;
  String? _selectedFilter;
  
  final List<String> _severityFilters = [
    'All',
    'healthy',
    'low',
    'medium',
    'high',
    'critical',
  ];

  @override
  void initState() {
    super.initState();
    _loadDetections();
  }

  Future<void> _loadDetections() async {
    setState(() => _isLoading = true);
    
    try {
      final detections = await _diseaseService.getDetections();
      if (mounted) {
        setState(() {
          _allDetections = detections;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading detections: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredDetections {
    if (_selectedFilter == null || _selectedFilter == 'All') {
      return _allDetections;
    }
    return _allDetections.where((d) => d['severity'] == _selectedFilter).toList();
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
              primaryColor,
              backgroundColor,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detect History',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Your disease detection records',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadDetections,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
              ),
            ],
          ),
          if (!_isLoading) ...[
            const SizedBox(height: 16),
            _buildStatsCards(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final stats = _calculateStats();
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Scans',
            '${stats['total']}',
            Icons.photo_camera,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Healthy',
            '${stats['healthy']}',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Diseases',
            '${stats['diseases']}',
            Icons.warning,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _severityFilters.length,
        itemBuilder: (context, index) {
          final severity = _severityFilters[index];
          final isSelected = _selectedFilter == severity || 
                            (severity == 'All' && _selectedFilter == null);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                severity == 'All' ? severity : severity[0].toUpperCase() + severity.substring(1),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = severity == 'All' ? null : severity;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: primaryColor.withOpacity(0.2),
              checkmarkColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? primaryColor : textDarkColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading detections...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _buildDetectionsList(),
        ),
      ],
    );
  }

  Widget _buildDetectionsList() {
    final detections = _filteredDetections;

    if (detections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_search,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No detections found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start scanning your crops',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: detections.length,
      itemBuilder: (context, index) {
        final detection = detections[index];
        return _buildDetectionCard(detection);
      },
    );
  }

  Widget _buildDetectionCard(Map<String, dynamic> detection) {
    final severity = detection['severity'] ?? 'unknown';
    final color = _getSeverityColor(severity);
    final icon = _getSeverityIcon(severity);
    final date = DateTime.parse(detection['detection_date']);
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);
    final confidence = (detection['confidence'] as num).toDouble();
    final diseaseName = detection['disease_name'] ?? 'Unknown';
    final isHealthy = diseaseName.toLowerCase().contains('healthy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showDetectionDetails(detection),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diseaseName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isHealthy ? Colors.green : Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.assessment, size: 14, color: textLightColor),
                        const SizedBox(width: 4),
                        Text(
                          '${confidence.toStringAsFixed(1)}% confidence',
                          style: const TextStyle(
                            fontSize: 13,
                            color: textLightColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textLightColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      severity[0].toUpperCase() + severity.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
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

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'low':
        return Colors.blue;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'healthy':
        return Icons.check_circle;
      case 'low':
        return Icons.info;
      case 'medium':
        return Icons.warning;
      case 'high':
        return Icons.error;
      case 'critical':
        return Icons.dangerous;
      default:
        return Icons.help;
    }
  }

  Map<String, dynamic> _calculateStats() {
    int healthyCount = 0;
    int diseaseCount = 0;

    for (var detection in _allDetections) {
      final diseaseName = (detection['disease_name'] ?? '').toString().toLowerCase();
      if (diseaseName.contains('healthy')) {
        healthyCount++;
      } else {
        diseaseCount++;
      }
    }

    return {
      'total': _allDetections.length,
      'healthy': healthyCount,
      'diseases': diseaseCount,
    };
  }

  void _showDetectionDetails(Map<String, dynamic> detection) {
    final date = DateTime.parse(detection['detection_date']);
    final formattedDate = DateFormat('MMMM dd, yyyy \'at\' h:mm a').format(date);
    final severity = detection['severity'] ?? 'unknown';
    final color = _getSeverityColor(severity);
    final confidence = (detection['confidence'] as num).toDouble();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Disease name header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_getSeverityIcon(severity), color: color, size: 40),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detection['disease_name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${severity[0].toUpperCase()}${severity.substring(1)} Severity',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Confidence meter
                    _buildDetailSection(
                      'Confidence Level',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${confidence.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              Text(
                                _getConfidenceLabel(confidence),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: textLightColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: confidence / 100,
                              minHeight: 12,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    _buildDetailRow(Icons.calendar_today, 'Detection Date', formattedDate),
                    
                    if (detection['location'] != null)
                      _buildDetailRow(Icons.location_on, 'Location', detection['location']),
                    
                    if (detection['crop_variety'] != null)
                      _buildDetailRow(Icons.grass, 'Crop Variety', detection['crop_variety']),
                    
                    if (detection['treatment_recommended'] != null)
                      _buildDetailSection(
                        'Recommended Treatment',
                        Text(
                          detection['treatment_recommended'],
                          style: const TextStyle(fontSize: 15, color: textDarkColor, height: 1.5),
                        ),
                      ),
                    
                    if (detection['notes'] != null)
                      _buildDetailRow(Icons.notes, 'Notes', detection['notes']),
                    
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmDelete(detection['id']);
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: textLightColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textLightColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textLightColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: textDarkColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getConfidenceLabel(double confidence) {
    if (confidence >= 90) return 'Very High';
    if (confidence >= 75) return 'High';
    if (confidence >= 60) return 'Moderate';
    if (confidence >= 45) return 'Low';
    return 'Very Low';
  }

  void _confirmDelete(String detectionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Detection'),
        content: const Text('Are you sure you want to delete this detection record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _diseaseService.deleteDetection(detectionId);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Detection deleted'),
                    backgroundColor: Colors.orange,
                  ),
                );
                _loadDetections();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
