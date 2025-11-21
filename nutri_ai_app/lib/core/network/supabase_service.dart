import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient? _instance;

  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
    
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );

    _instance = Supabase.instance.client;
  }

  static SupabaseClient get client {
    if (_instance == null) {
      throw Exception('Supabase não foi inicializado');
    }
    return _instance!;
  }
}
