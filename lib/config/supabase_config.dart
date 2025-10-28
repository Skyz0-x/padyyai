import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://zwkntyiujwglpibmftzf.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3a250eWl1andnbHBpYm1mdHpmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1NzEwNjgsImV4cCI6MjA3NzE0NzA2OH0.YlSXKfUqagJf6Z693RzgRGP9wgH7RHidjUwvpV5-8Ns';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}