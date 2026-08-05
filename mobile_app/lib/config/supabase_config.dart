import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'file_io_stub.dart' if (dart.library.io) 'file_io.dart';

class SupabaseConfig {
  // Use runtime-settable static fields instead of compile-time consts so we
  // can fall back to a local JSON file when --dart-define is not provided.
  static String url = const String.fromEnvironment('SUPABASE_URL');
  static String publishableKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Validate configuration. If the compile-time defines are empty, on
  /// non-web platforms we try to load `dart_define.json` from a few
  /// candidate locations (project root, parent, mobile_app/).
  ///
  /// On web we cannot access the local filesystem, so the original
  /// error is thrown if defines are missing.
  static Future<void> validate() async {
    if (url.isNotEmpty && publishableKey.isNotEmpty) return;

    if (!kIsWeb) {
      final candidates = <String>[
        'dart_define.json',
        '../dart_define.json',
        'mobile_app/dart_define.json',
      ];

      for (final p in candidates) {
        try {
          final content = await readFileIfExists(p);
          if (content == null) continue;
          final map = jsonDecode(content) as Map<String, dynamic>;
          final u = (map['SUPABASE_URL'] ?? '').toString();
          final k = (map['SUPABASE_ANON_KEY'] ?? '').toString();
          if (u.isNotEmpty && k.isNotEmpty) {
            url = u;
            publishableKey = k;
            return;
          }
        } catch (_) {
          // ignore and try next candidate
        }
      }
    }

    throw StateError(
      'Configure SUPABASE_URL e SUPABASE_ANON_KEY via --dart-define-from-file or provide a dart_define.json in project root.',
    );
  }
}
