import '../config/supabase_config.dart';

class DiseaseRecordsService {
  final _client = SupabaseConfig.client;

  // Add a new disease detection record
  Future<Map<String, dynamic>> addDetection({
    required String diseaseName,
    required double confidence,
    String? imageUrl,
    String? severity,
    String? location,
    String? cropVariety,
    String? treatmentRecommended,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final response = await _client.from('disease_detections').insert({
        'user_id': userId,
        'disease_name': diseaseName,
        'confidence': confidence,
        'image_url': imageUrl,
        'severity': severity,
        'location': location,
        'crop_variety': cropVariety,
        'treatment_recommended': treatmentRecommended,
        'notes': notes,
        'detection_date': DateTime.now().toIso8601String(),
      }).select();

      print('✅ Disease detection saved successfully');
      return {
        'success': true,
        'message': 'Detection saved',
        'data': response[0],
      };
    } catch (e) {
      print('❌ Error saving disease detection: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get all disease detections for current user
  Future<List<Map<String, dynamic>>> getDetections({
    String? diseaseName,
    String? severity,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _client
          .from('disease_detections')
          .select()
          .eq('user_id', userId);

      if (diseaseName != null) {
        query = query.eq('disease_name', diseaseName);
      }

      if (severity != null) {
        query = query.eq('severity', severity);
      }

      if (startDate != null) {
        query = query.gte('detection_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('detection_date', endDate.toIso8601String());
      }

      final response = await query.order('detection_date', ascending: false);
      print('✅ Retrieved ${response.length} disease detections');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting disease detections: $e');
      return [];
    }
  }

  // Get detection statistics
  Future<Map<String, dynamic>> getDetectionStats() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {};

      final detections = await _client
          .from('disease_detections')
          .select()
          .eq('user_id', userId);

      // Calculate statistics
      int totalDetections = detections.length;
      int healthyCount = 0;
      int diseaseCount = 0;
      double totalConfidence = 0;
      Map<String, int> diseaseTypeCount = {};
      Map<String, int> severityCount = {};

      for (var detection in detections) {
        final diseaseName = (detection['disease_name'] ?? '').toString().toLowerCase();
        
        if (diseaseName.contains('healthy')) {
          healthyCount++;
        } else {
          diseaseCount++;
        }

        totalConfidence += (detection['confidence'] as num).toDouble();

        // Count by disease type
        String disease = detection['disease_name'] ?? 'Unknown';
        diseaseTypeCount[disease] = (diseaseTypeCount[disease] ?? 0) + 1;

        // Count by severity
        String severity = detection['severity'] ?? 'unknown';
        severityCount[severity] = (severityCount[severity] ?? 0) + 1;
      }

      double avgConfidence = totalDetections > 0 ? totalConfidence / totalDetections : 0;

      return {
        'total_detections': totalDetections,
        'healthy_count': healthyCount,
        'disease_count': diseaseCount,
        'avg_confidence': avgConfidence,
        'by_disease': diseaseTypeCount,
        'by_severity': severityCount,
      };
    } catch (e) {
      print('❌ Error getting detection stats: $e');
      return {};
    }
  }

  // Update detection record
  Future<bool> updateDetection(String detectionId, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('disease_detections')
          .update(updates)
          .eq('id', detectionId);

      print('✅ Disease detection updated');
      return true;
    } catch (e) {
      print('❌ Error updating disease detection: $e');
      return false;
    }
  }

  // Delete detection record
  Future<bool> deleteDetection(String detectionId) async {
    try {
      await _client
          .from('disease_detections')
          .delete()
          .eq('id', detectionId);

      print('✅ Disease detection deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting disease detection: $e');
      return false;
    }
  }

  // Get unique disease names (for filtering)
  Future<List<String>> getUniqueDiseaseNames() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final detections = await _client
          .from('disease_detections')
          .select('disease_name')
          .eq('user_id', userId);

      final diseaseNames = detections
          .map((d) => d['disease_name'] as String)
          .toSet()
          .toList();

      return diseaseNames;
    } catch (e) {
      print('❌ Error getting disease names: $e');
      return [];
    }
  }
}
