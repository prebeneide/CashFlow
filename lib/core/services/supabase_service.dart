import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
  
  static User? get currentUser => client.auth.currentUser;
  
  static bool get isAuthenticated {
    final session = client.auth.currentSession;
    return session != null;
  }
}

