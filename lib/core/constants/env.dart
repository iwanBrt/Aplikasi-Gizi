import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  //static const String openRouterApiKey = "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";
}
