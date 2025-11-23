import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../l10n/app_locale.dart';
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
  
  List<String> _diseaseFilters = [];

  @override
  void initState() {
    super.initState();
    _loadDetections();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize filters after context is available
    if (_diseaseFilters.isEmpty) {
      _diseaseFilters = [
        AppLocale.all.getString(context),
        AppLocale.healthyPlant.getString(context),
        AppLocale.brownPlanthopper.getString(context),
        AppLocale.brownSpot.getString(context),
        AppLocale.leafBlast.getString(context),
        AppLocale.leafScald.getString(context),
        AppLocale.riceLeafroller.getString(context),
        AppLocale.riceYellowStemBorer.getString(context),
        AppLocale.sheathBlight.getString(context),
      ];
    }
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
    if (_selectedFilter == null || _selectedFilter == AppLocale.all.getString(context)) {
      return _allDetections;
    }
    return _allDetections.where((d) => 
      (d['disease_name'] ?? '').toString().toLowerCase() == _selectedFilter!.toLowerCase()
    ).toList();
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
                    Text(
                      AppLocale.detectHistory.getString(context),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      AppLocale.diseaseDetectionRecords.getString(context),
                      style: const TextStyle(
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
                tooltip: AppLocale.refresh.getString(context),
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
            AppLocale.totalScans.getString(context),
            '${stats['total']}',
            Icons.photo_camera,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            AppLocale.healthy.getString(context),
            '${stats['healthy']}',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            AppLocale.diseases.getString(context),
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
        itemCount: _diseaseFilters.length,
        itemBuilder: (context, index) {
          final disease = _diseaseFilters[index];
          final allText = AppLocale.all.getString(context);
          final isSelected = _selectedFilter == disease || 
                            (disease == allText && _selectedFilter == null);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(disease),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = disease == allText ? null : disease;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: primaryColor.withOpacity(0.2),
              checkmarkColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? primaryColor : textDarkColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
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
              AppLocale.noDetectionsFound.getString(context),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocale.startScanningCrops.getString(context),
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
    final diseaseNameRaw = detection['disease_name'] ?? AppLocale.unknownDisease.getString(context);
    final diseaseName = _getLocalizedDiseaseName(diseaseNameRaw);
    final color = _getSeverityColor(diseaseNameRaw);
    final icon = _getSeverityIcon(diseaseNameRaw);
    final date = DateTime.parse(detection['detection_date']);
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);
    final isHealthy = diseaseNameRaw.toLowerCase().contains('healthy');

    return Dismissible(
      key: Key(detection['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete, color: Colors.white, size: 32),
            const SizedBox(height: 4),
            Text(
              AppLocale.clear.getString(context),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocale.deleteDetection.getString(context)),
            content: Text(AppLocale.deleteDetectionConfirm.getString(context)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocale.cancel.getString(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(AppLocale.remove.getString(context)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        final success = await _diseaseService.deleteDetection(detection['id']);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$diseaseName ${AppLocale.detectionDeleted.getString(context)}'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'UNDO',
                textColor: Colors.white,
                onPressed: () {
                  // Note: Undo would require storing the deleted data
                  // For now, just reload
                  _loadDetections();
                },
              ),
            ),
          );
          _loadDetections();
        }
      },
      child: Container(
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
                      const SizedBox(height: 8),
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
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red.shade400,
                  onPressed: () => _confirmDelete(detection['id']),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    // Return green for healthy, red for diseases
    if (severity.toLowerCase().contains('healthy')) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  IconData _getSeverityIcon(String severity) {
    final name = severity.toLowerCase();
    
    // Return check_circle for healthy
    if (name.contains('healthy')) {
      return Icons.check_circle;
    }
    
    // Pests - use bug_report icon
    if (name.contains('planthopper') || 
        name.contains('leafroller') || 
        name.contains('borer')) {
      return Icons.bug_report;
    }
    
    // Fungicides - use coronavirus (fungus-like) icon
    if (name.contains('blast') || 
        name.contains('spot') || 
        name.contains('blight') || 
        name.contains('scald')) {
      return Icons.coronavirus;
    }
    
    // Default
    return Icons.warning;
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

  String _getLocalizedDiseaseName(String diseaseName) {
    final normalizedName = diseaseName.toLowerCase().replaceAll(' ', '_');
    
    switch (normalizedName) {
      case 'brown_planthopper':
      case 'brownplanthopper':
        return AppLocale.brownPlanthopper.getString(context);
      case 'brown_spot':
      case 'brownspot':
        return AppLocale.brownSpot.getString(context);
      case 'healthy':
      case 'healthy_plant':
        return AppLocale.healthyPlant.getString(context);
      case 'leaf_blast':
      case 'leafblast':
        return AppLocale.leafBlast.getString(context);
      case 'leaf_scald':
      case 'leafscald':
        return AppLocale.leafScald.getString(context);
      case 'rice_leafroller':
      case 'riceleafroller':
        return AppLocale.riceLeafroller.getString(context);
      case 'rice_yellow_stem_borer':
      case 'riceyellowstemborer':
        return AppLocale.riceYellowStemBorer.getString(context);
      case 'sheath_blight':
      case 'sheathblight':
        return AppLocale.sheathBlight.getString(context);
      default:
        return diseaseName;
    }
  }

  void _showDetectionDetails(Map<String, dynamic> detection) {
    final date = DateTime.parse(detection['detection_date']);
    final formattedDate = DateFormat('MMMM dd, yyyy \'at\' h:mm a').format(date);
    final diseaseNameRaw = detection['disease_name'] ?? AppLocale.unknownDisease.getString(context);
    final diseaseName = _getLocalizedDiseaseName(diseaseNameRaw);
    final color = _getSeverityColor(diseaseNameRaw);

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
                          child: Icon(_getSeverityIcon(diseaseNameRaw), color: color, size: 40),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                diseaseName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Detection image (if available)
                    if (detection['image_url'] != null) ...[
                      _buildDetailSection(
                        AppLocale.scannedImage.getString(context),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            detection['image_url'],
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, 
                                      size: 60, 
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLocale.imageNotAvailable.getString(context),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    
                    _buildDetailRow(Icons.calendar_today, AppLocale.detectionDate.getString(context), formattedDate),
                    
                    if (detection['location'] != null)
                      _buildDetailRow(Icons.location_on, 'Location', detection['location']),
                    
                    if (detection['crop_variety'] != null)
                      _buildDetailRow(Icons.grass, AppLocale.cropVariety.getString(context), detection['crop_variety']),
                    
                    if (detection['treatment_recommended'] != null)
                      _buildDetailSection(
                        AppLocale.recommendedTreatment.getString(context),
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
                            label: Text(AppLocale.remove.getString(context)),
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

  void _confirmDelete(String detectionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocale.deleteDetection.getString(context)),
        content: Text(AppLocale.deleteDetectionConfirm.getString(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocale.cancel.getString(context)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _diseaseService.deleteDetection(detectionId);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocale.detectionDeleted.getString(context)),
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
