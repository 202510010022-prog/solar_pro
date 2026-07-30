class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static void validate() {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Configure SUPABASE_URL e SUPABASE_ANON_KEY via --dart-define-from-file.',
      );
    }
  }
}
