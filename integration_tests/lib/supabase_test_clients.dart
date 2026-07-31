import 'dart:convert';
import 'dart:io';

import 'package:supabase/supabase.dart';

import 'test_env.dart';
import 'test_fixtures.dart';

class SupabaseTestClients {
  SupabaseTestClients(this.env);

  final TestEnv env;

  SupabaseClient get serviceRoleClient => SupabaseClient(
    env.supabaseUrl,
    env.serviceRoleKey,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );

  SupabaseClient anonClient() => SupabaseClient(
    env.supabaseUrl,
    env.anonKey,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );

  Future<SupabaseClient> signInAs(FixtureUser user) async {
    final client = anonClient();
    await client.auth.signInWithPassword(
      email: user.email,
      password: user.password,
    );
    return client;
  }
}

class SupabaseAdminApi {
  SupabaseAdminApi(this.env);

  final TestEnv env;

  Uri authAdminUri([String path = '']) {
    final base = env.supabaseUrl.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base/auth/v1/admin/users$path');
  }

  Future<String> createAuthUser({
    required String email,
    required String password,
    required String name,
    required String matricula,
    required String role,
    required String permission,
  }) async {
    final response = await _request(
      'POST',
      authAdminUri(),
      body: {
        'email': email,
        'password': password,
        'email_confirm': true,
        'user_metadata': {
          'name': name,
          'matricula': matricula,
          'role': role,
          'permission': permission,
        },
      },
    );
    final id = '${response['id'] ?? ''}';
    if (id.isEmpty) {
      throw StateError('Usuario Auth criado sem ID para $email.');
    }
    return id;
  }

  Future<void> deleteAuthUser(String userId) async {
    if (userId.isEmpty) return;
    await _request('DELETE', authAdminUri('/$userId'), allowNotFound: true);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    bool allowNotFound = false,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, uri);
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${env.serviceRoleKey}',
      );
      request.headers.set('apikey', env.serviceRoleKey);
      request.headers.contentType = ContentType.json;
      if (body != null) {
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      final text = await utf8.decodeStream(response);
      if (allowNotFound && response.statusCode == HttpStatus.notFound) {
        return const {};
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Supabase Admin API falhou ($method $uri): '
          '${response.statusCode} $text',
        );
      }
      if (text.trim().isEmpty) return const {};
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return const {};
    } finally {
      client.close(force: true);
    }
  }
}
