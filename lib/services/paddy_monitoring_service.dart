import '../config/supabase_config.dart';

class PaddyMonitoringService {
  final _client = SupabaseConfig.client;

  // Save or update paddy monitoring data
  Future<Map<String, dynamic>> savePaddyMonitoring({
    required String variety,
    required DateTime plantingDate,
    required int estimatedHarvestDaysMin,
    required int estimatedHarvestDaysMax,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Check if user already has an active monitoring record
      final existingRecords = await _client
          .from('paddy_monitoring')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .limit(1);

      if (existingRecords.isNotEmpty) {
        // Update existing record
        final recordId = existingRecords[0]['id'];
        await _client.from('paddy_monitoring').update({
          'variety': variety,
          'planting_date': plantingDate.toIso8601String().split('T')[0],
          'estimated_harvest_days_min': estimatedHarvestDaysMin,
          'estimated_harvest_days_max': estimatedHarvestDaysMax,
          'notes': notes,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', recordId);

        print('✅ Paddy monitoring updated successfully');
        return {
          'success': true,
          'message': 'Monitoring updated successfully',
          'id': recordId,
        };
      } else {
        // Create new record
        final response = await _client.from('paddy_monitoring').insert({
          'user_id': userId,
          'variety': variety,
          'planting_date': plantingDate.toIso8601String().split('T')[0],
          'estimated_harvest_days_min': estimatedHarvestDaysMin,
          'estimated_harvest_days_max': estimatedHarvestDaysMax,
          'status': 'active',
          'notes': notes,
        }).select();

        print('✅ Paddy monitoring saved successfully');
        return {
          'success': true,
          'message': 'Monitoring saved successfully',
          'id': response[0]['id'],
        };
      }
    } catch (e) {
      print('❌ Error saving paddy monitoring: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Get active paddy monitoring for current user
  Future<Map<String, dynamic>?> getActivePaddyMonitoring() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        print('⚠️ User not authenticated');
        return null;
      }

      final response = await _client
          .from('paddy_monitoring')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        print('✅ Active paddy monitoring found');
        return response[0];
      }

      print('ℹ️ No active paddy monitoring found');
      return null;
    } catch (e) {
      print('❌ Error getting paddy monitoring: $e');
      return null;
    }
  }

  // Get all paddy monitoring records for current user
  Future<List<Map<String, dynamic>>> getAllPaddyMonitoring() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        print('⚠️ User not authenticated');
        return [];
      }

      final response = await _client
          .from('paddy_monitoring')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print('✅ Retrieved ${response.length} paddy monitoring records');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error getting all paddy monitoring: $e');
      return [];
    }
  }

  // Mark paddy as harvested
  Future<bool> markAsHarvested(String recordId) async {
    try {
      await _client
          .from('paddy_monitoring')
          .update({
            'status': 'harvested',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', recordId);

      print('✅ Paddy monitoring marked as harvested');
      return true;
    } catch (e) {
      print('❌ Error marking as harvested: $e');
      return false;
    }
  }

  // Delete paddy monitoring record
  Future<bool> deletePaddyMonitoring(String recordId) async {
    try {
      await _client.from('paddy_monitoring').delete().eq('id', recordId);

      print('✅ Paddy monitoring deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting paddy monitoring: $e');
      return false;
    }
  }

  // Update notes
  Future<bool> updateNotes(String recordId, String notes) async {
    try {
      await _client.from('paddy_monitoring').update({
        'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', recordId);

      print('✅ Notes updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating notes: $e');
      return false;
    }
  }
}
