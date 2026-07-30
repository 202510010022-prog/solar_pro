import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_profile.dart';
import '../models/team_invite_result.dart';

class TeamService {
  TeamService(
    this._supabase, {
    required this.currentCompanyId,
    required this.ensureCompanyCanWrite,
  });

  final SupabaseClient _supabase;
  final Future<String> Function() currentCompanyId;
  final Future<void> Function(String action) ensureCompanyCanWrite;

  Future<List<AppProfile>> loadTeamProfiles() async {
    final companyId = await currentCompanyId();
    final rows = await _supabase
        .from('profiles')
        .select()
        .eq('company_id', companyId)
        .order('active', ascending: false)
        .order('name');
    return rows
        .map((row) => AppProfile.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<TeamInviteResult> inviteTeamUser({
    required String name,
    required String email,
    required String matricula,
    required String permission,
    required String role,
    String password = '',
  }) async {
    await ensureCompanyCanWrite('convidar usuários');
    try {
      final response = await _supabase.functions.invoke(
        'invite-user',
        body: {
          'name': name,
          'email': email,
          'matricula': matricula,
          'permission': permission,
          'role': role,
          if (password.trim().isNotEmpty) 'password': password.trim(),
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return TeamInviteResult.fromMap(data);
      }
      if (data is Map) {
        return TeamInviteResult.fromMap(Map<String, dynamic>.from(data));
      }
      throw StateError('Resposta invalida da funcao de convite.');
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        throw StateError('${details['error']}');
      }
      throw StateError(error.reasonPhrase ?? 'Nao foi possivel criar usuario.');
    }
  }

  Future<void> updateTeamUser({
    required String profileId,
    required String name,
    required String email,
    required String matricula,
    required String permission,
    required String role,
    required bool active,
    String password = '',
  }) async {
    await ensureCompanyCanWrite('editar usuários');
    try {
      final response = await _supabase.functions.invoke(
        'invite-user',
        body: {
          'action': 'update_user',
          'id': profileId,
          'name': name,
          'email': email,
          'matricula': matricula,
          'permission': permission,
          'role': role,
          'active': active,
          if (password.trim().isNotEmpty) 'password': password.trim(),
        },
      );
      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw StateError('${data['error']}');
      }
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        throw StateError('${details['error']}');
      }
      throw StateError(
        error.reasonPhrase ?? 'Nao foi possivel atualizar usuario.',
      );
    }
  }

  Future<void> deleteTeamUser(String profileId) async {
    await ensureCompanyCanWrite('excluir usuários');
    try {
      final response = await _supabase.functions.invoke(
        'invite-user',
        body: {'action': 'delete_user', 'id': profileId},
      );
      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw StateError('${data['error']}');
      }
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        throw StateError('${details['error']}');
      }
      throw StateError(
          error.reasonPhrase ?? 'Nao foi possivel excluir usuario.');
    }
  }
}
