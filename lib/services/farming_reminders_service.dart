import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class FarmingRemindersService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get all reminders for current user
  Future<List<Map<String, dynamic>>> getAllReminders({
    bool includeCompleted = false,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _supabase
          .from('farming_reminders')
          .select();

      if (!includeCompleted) {
        query = query.eq('is_completed', false);
      }

      if (fromDate != null) {
        query = query.gte('scheduled_date', fromDate.toIso8601String());
      }

      if (toDate != null) {
        query = query.lte('scheduled_date', toDate.toIso8601String());
      }

      final response = await query.order('scheduled_date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reminders: $e');
      return [];
    }
  }

  // Get upcoming reminders (next 7 days)
  Future<List<Map<String, dynamic>>> getUpcomingReminders({int days = 7}) async {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));
    
    return getAllReminders(
      fromDate: now,
      toDate: futureDate,
      includeCompleted: false,
    );
  }

  // Get today's reminders
  Future<List<Map<String, dynamic>>> getTodayReminders() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return getAllReminders(
      fromDate: today,
      toDate: tomorrow,
      includeCompleted: false,
    );
  }

  // Get reminders for a specific date
  Future<List<Map<String, dynamic>>> getRemindersByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('farming_reminders')
          .select()
          .gte('scheduled_date', startOfDay.toIso8601String())
          .lt('scheduled_date', endOfDay.toIso8601String())
          .order('scheduled_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reminders by date: $e');
      return [];
    }
  }

  // Get reminders for a specific month (for calendar view)
  Future<Map<DateTime, List<Map<String, dynamic>>>> getRemindersByMonth(
    int year,
    int month,
  ) async {
    try {
      final firstDay = DateTime(year, month, 1);
      final lastDay = DateTime(year, month + 1, 0);

      final response = await _supabase
          .from('farming_reminders')
          .select()
          .gte('scheduled_date', firstDay.toIso8601String())
          .lte('scheduled_date', lastDay.toIso8601String())
          .order('scheduled_date', ascending: true);

      final reminders = List<Map<String, dynamic>>.from(response);
      final Map<DateTime, List<Map<String, dynamic>>> remindersByDate = {};

      for (var reminder in reminders) {
        final scheduledDate = DateTime.parse(reminder['scheduled_date']);
        final dateKey = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
        
        if (!remindersByDate.containsKey(dateKey)) {
          remindersByDate[dateKey] = [];
        }
        remindersByDate[dateKey]!.add(reminder);
      }

      return remindersByDate;
    } catch (e) {
      print('Error fetching reminders by month: $e');
      return {};
    }
  }

  // Get reminders by type
  Future<List<Map<String, dynamic>>> getRemindersByType(String type) async {
    try {
      final response = await _supabase
          .from('farming_reminders')
          .select()
          .eq('reminder_type', type)
          .order('scheduled_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reminders by type: $e');
      return [];
    }
  }

  // Get count of pending notifications
  Future<int> getPendingNotificationsCount() async {
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      
      final response = await _supabase
          .from('farming_reminders')
          .select()
          .eq('notification_sent', false)
          .eq('is_completed', false)
          .lte('scheduled_date', tomorrow.toIso8601String());

      return (response as List).length;
    } catch (e) {
      print('Error getting notification count: $e');
      return 0;
    }
  }

  // Create a new reminder
  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> reminderData) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final data = {...reminderData, 'user_id': userId};
      
      await _supabase.from('farming_reminders').insert(data);

      return {'success': true, 'message': 'Reminder created successfully'};
    } catch (e) {
      print('Error creating reminder: $e');
      return {'success': false, 'message': 'Failed to create reminder: $e'};
    }
  }

  // Update reminder
  Future<Map<String, dynamic>> updateReminder(
    String reminderId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _supabase
          .from('farming_reminders')
          .update(updates)
          .eq('id', reminderId);

      return {'success': true, 'message': 'Reminder updated successfully'};
    } catch (e) {
      print('Error updating reminder: $e');
      return {'success': false, 'message': 'Failed to update reminder: $e'};
    }
  }

  // Mark reminder as completed
  Future<Map<String, dynamic>> markAsCompleted(String reminderId) async {
    return updateReminder(reminderId, {'is_completed': true});
  }

  // Mark notification as sent
  Future<Map<String, dynamic>> markNotificationSent(String reminderId) async {
    return updateReminder(reminderId, {'notification_sent': true});
  }

  // Delete reminder
  Future<Map<String, dynamic>> deleteReminder(String reminderId) async {
    try {
      await _supabase
          .from('farming_reminders')
          .delete()
          .eq('id', reminderId);

      return {'success': true, 'message': 'Reminder deleted successfully'};
    } catch (e) {
      print('Error deleting reminder: $e');
      return {'success': false, 'message': 'Failed to delete reminder: $e'};
    }
  }
}
