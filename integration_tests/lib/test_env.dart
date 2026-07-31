import 'dart:io';

class TestEnv {
  const TestEnv({
    required this.supabaseUrl,
    required this.anonKey,
    required this.serviceRoleKey,
  });

  final String supabaseUrl;
  final String anonKey;
  final String serviceRoleKey;

  static Future<TestEnv> load({String path = '.env'}) async {
    final fileValues = await _readDotEnv(path);
    final supabaseUrl = _value('SUPABASE_URL', fileValues);
    final anonKey = _value('SUPABASE_ANON_KEY', fileValues);
    final serviceRoleKey = _value('SUPABASE_SERVICE_ROLE_KEY', fileValues);

    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (anonKey.isEmpty) 'SUPABASE_ANON_KEY',
      if (serviceRoleKey.isEmpty) 'SUPABASE_SERVICE_ROLE_KEY',
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Configure ${missing.join(', ')} em $path ou como variavel de ambiente.',
      );
    }

    return TestEnv(
      supabaseUrl: supabaseUrl,
      anonKey: anonKey,
      serviceRoleKey: serviceRoleKey,
    );
  }

  static String _value(String key, Map<String, String> fileValues) {
    return (Platform.environment[key] ?? fileValues[key] ?? '').trim();
  }

  static Future<Map<String, String>> _readDotEnv(String path) async {
    final file = File(path);
    if (!await file.exists()) return const {};

    final values = <String, String>{};
    for (final rawLine in await file.readAsLines()) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final separator = line.indexOf('=');
      if (separator <= 0) continue;
      final key = line.substring(0, separator).trim();
      var value = line.substring(separator + 1).trim();
      if (value.length >= 2) {
        final quoted =
            (value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"));
        if (quoted) value = value.substring(1, value.length - 1);
      }
      values[key] = value;
    }
    return values;
  }
}
