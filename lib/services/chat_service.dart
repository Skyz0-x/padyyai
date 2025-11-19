import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Send message to AI chatbot
  Future<String> sendMessage(
    String message, {
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'chat-rice-tips',
        body: {
          'message': message,
          if (conversationHistory != null)
            'conversationHistory': conversationHistory,
        },
      );

      if (response.data == null) {
        throw Exception('No response from chat service');
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true && data['response'] != null) {
        return data['response'] as String;
      } else {
        throw Exception(data['error'] ?? 'Failed to get response');
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Save chat message to database (optional - for history tracking)
  Future<void> saveChatMessage({
    required String message,
    required String response,
    required bool isUserMessage,
  }) async {
    try {
      await _supabase.from('chat_messages').insert({
        'user_id': _supabase.auth.currentUser?.id,
        'message': message,
        'response': response,
        'is_user_message': isUserMessage,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving chat message: $e');
      // Don't throw - saving chat history is optional
    }
  }

  // Get chat history (optional)
  Future<List<Map<String, dynamic>>> getChatHistory() async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('user_id', _supabase.auth.currentUser?.id ?? '')
          .order('created_at', ascending: true)
          .limit(50);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error getting chat history: $e');
      return [];
    }
  }

  // Clear chat history (optional)
  Future<void> clearChatHistory() async {
    try {
      await _supabase
          .from('chat_messages')
          .delete()
          .eq('user_id', _supabase.auth.currentUser?.id ?? '');
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }
}
