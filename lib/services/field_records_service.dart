import '../config/supabase_config.dart';

class FieldRecordsService {
  final _client = SupabaseConfig.client;

  // Add a new field record
  Future<Map<String, dynamic>> addFieldRecord({
    required String recordType,
    required String title,
    String? description,
    double? areaSize,
    double? quantity,
    String? unit,
    double? cost,
    String? location,
    String? weatherCondition,
    String? notes,
    DateTime? recordDate,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final response = await _client.from('field_records').insert({
        'user_id': userId,
        'record_type': recordType,
        'title': title,
        'description': description,
        'area_size': areaSize,
        'quantity': quantity,
        'unit': unit,
        'cost': cost,
        'location': location,
        'weather_condition': weatherCondition,
        'notes': notes,
        'record_date': (recordDate ?? DateTime.now()).toIso8601String().split('T')[0],
      }).select();

      print('✅ Field record added successfully');
      return {
        'success': true,
        'message': 'Field record added',
        'data': response[0],
      };
    } catch (e) {
      print('❌ Error adding field record: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get all field records for current user
  Future<List<Map<String, dynamic>>> getFieldRecords({
    String? recordType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _client
          .from('field_records')
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null);

      if (recordType != null) {
        query = query.eq('record_type', recordType);
      }

      if (startDate != null) {
        query = query.gte('record_date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('record_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('record_date', ascending: false);
      print('✅ Retrieved ${response.length} field records');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting field records: $e');
      return [];
    }
  }

  // Get field records statistics
  Future<Map<String, dynamic>> getFieldRecordsStats() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return {};

      final records = await _client
          .from('field_records')
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null);

      // Calculate statistics
      int totalRecords = records.length;
      double totalCost = 0;
      Map<String, int> recordTypeCount = {};

      for (var record in records) {
        if (record['cost'] != null) {
          totalCost += (record['cost'] as num).toDouble();
        }
        
        String type = record['record_type'] ?? 'other';
        recordTypeCount[type] = (recordTypeCount[type] ?? 0) + 1;
      }

      return {
        'total_records': totalRecords,
        'total_cost': totalCost,
        'by_type': recordTypeCount,
      };
    } catch (e) {
      print('❌ Error getting stats: $e');
      return {};
    }
  }

  // Update field record
  Future<bool> updateFieldRecord(String recordId, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('field_records')
          .update(updates)
          .eq('id', recordId);

      print('✅ Field record updated');
      return true;
    } catch (e) {
      print('❌ Error updating field record: $e');
      return false;
    }
  }

  // Delete field record (soft delete)
  Future<bool> deleteFieldRecord(String recordId) async {
    try {
      await _client
          .from('field_records')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', recordId);

      print('✅ Field record deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting field record: $e');
      return false;
    }
  }

  // Manually trigger cleanup of old records (30+ days)
  Future<void> cleanupOldRecords() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      await _client
          .from('field_records')
          .delete()
          .lt('record_date', cutoffDate.toIso8601String().split('T')[0]);

      print('✅ Cleaned up old field records');
    } catch (e) {
      print('❌ Error cleaning up records: $e');
    }
  }
}
