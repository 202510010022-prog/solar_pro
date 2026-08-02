import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project.dart';
import '../models/project_status.dart';
import 'cache_service.dart';

class ProjectService {
  ProjectService(
    this._supabase,
    this._cache, {
    required this.currentCompanyId,
    required this.currentUserId,
    required this.cacheKey,
    required this.ensureCompanyCanWrite,
  });

  final SupabaseClient _supabase;
  final CacheService _cache;
  final Future<String> Function() currentCompanyId;
  final String? Function() currentUserId;
  final String Function(String key) cacheKey;
  final Future<void> Function(String action) ensureCompanyCanWrite;

  Future<List<Project>> loadProjects({bool cacheFirst = true}) async {
    final companyId = await currentCompanyId();
    final key = cacheKey('projects');
    if (cacheFirst) {
      final cached = await _cache.loadJsonList(key);
      if (cached.isNotEmpty) {
        refreshProjectsInBackground();
        return cached.map(Project.fromMap).toList();
      }
    }

    final rows = await _supabase
        .from('projects')
        .select('*, clients(name)')
        .eq('company_id', companyId)
        .order('id', ascending: false);
    final data = rows.map((row) => Map<String, dynamic>.from(row)).toList();
    await _cache.saveJsonList(key, data);
    return data.map(Project.fromMap).toList();
  }

  Future<void> updateProjectStatus(
    int projectId,
    String status, {
    String? rejectionReason,
  }) async {
    await ensureCompanyCanWrite('alterar projetos');
    final previous = await _loadProjectStatusLogData(projectId);
    await _supabase.from('projects').update({
      'status': status,
      'rejection_reason': ProjectStatus.rejected.matches(status)
          ? (rejectionReason ?? '').trim()
          : '',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', projectId);
    await _insertStatusChangeHistory(
      projectId: projectId,
      previous: previous,
      nextStatus: status,
      rejectionReason: rejectionReason,
    );
    await refreshProjectsInBackground();
  }

  Future<void> updateProjectSummary({
    required int projectId,
    required String status,
    required double projectValue,
    required double laborCost,
    required double moduleUnitCost,
    required double inverterCost,
    required double supportCost,
    required List<Map<String, dynamic>> extraMaterials,
    required double energyTariff,
    required double modulePower,
    required double paybackYears,
    String? rejectionReason,
  }) async {
    await ensureCompanyCanWrite('editar projetos');
    final previous = await _loadProjectStatusLogData(projectId);
    await _supabase.from('projects').update({
      'status': status,
      'rejection_reason': ProjectStatus.rejected.matches(status)
          ? (rejectionReason ?? '').trim()
          : '',
      'project_value': projectValue,
      'labor_cost': laborCost,
      'module_unit_cost': moduleUnitCost,
      'inverter_cost': inverterCost,
      'support_cost': supportCost,
      'extra_materials': jsonEncode(extraMaterials),
      'energy_tariff': energyTariff,
      'module_power': modulePower,
      'payback_years': paybackYears,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', projectId);
    await _insertStatusChangeHistory(
      projectId: projectId,
      previous: previous,
      nextStatus: status,
      rejectionReason: rejectionReason,
    );
    await refreshProjectsInBackground();
  }

  Future<void> deleteProject(int projectId) async {
    await ensureCompanyCanWrite('excluir projetos');
    await _supabase.from('projects').delete().eq('id', projectId);
    await refreshProjectsInBackground();
  }

  Future<void> createFollowUpMessage(Project project) async {
    await ensureCompanyCanWrite('enviar follow-up');
    final projectId = project.id;
    if (projectId == null) throw StateError('Projeto sem ID.');
    final companyId = await currentCompanyId();
    final clientName = project.clientName.trim().isEmpty
        ? 'Cliente sem nome'
        : project.clientName;

    await _supabase.from('app_messages').insert({
      'company_id': companyId,
      'title': 'Follow-up sugerido',
      'message':
          'Enviar follow-up para $clientName sobre o projeto #$projectId em negociação.',
      'type': 'warning',
      'status': 'unread',
      'created_by': currentUserId(),
    });

    await _supabase
        .from('projects')
        .update({
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', projectId)
        .eq('company_id', companyId);
    await refreshProjectsInBackground();
  }

  Future<void> refreshProjectsInBackground() async {
    try {
      final companyId = await currentCompanyId();
      final rows = await _supabase
          .from('projects')
          .select('*, clients(name)')
          .eq('company_id', companyId)
          .order('id', ascending: false);
      await _cache.saveJsonList(
        cacheKey('projects'),
        rows.map((row) => Map<String, dynamic>.from(row)).toList(),
      );
    } catch (_) {
      // Offline-first: cache remains valid when network is unavailable.
    }
  }

  Future<_ProjectStatusLogData?> _loadProjectStatusLogData(
    int projectId,
  ) async {
    try {
      final row = await _supabase
          .from('projects')
          .select('id, status, clients(name)')
          .eq('id', projectId)
          .maybeSingle();
      if (row == null) return null;
      return _ProjectStatusLogData.fromMap(Map<String, dynamic>.from(row));
    } catch (error) {
      debugPrint('Falha ao carregar projeto para historico: $error');
      return null;
    }
  }

  Future<void> _insertStatusChangeHistory({
    required int projectId,
    required _ProjectStatusLogData? previous,
    required String nextStatus,
    required String? rejectionReason,
  }) async {
    final oldStatus = previous?.status;
    if (oldStatus != null &&
        ProjectStatus.fromDbValue(oldStatus) ==
            ProjectStatus.fromDbValue(nextStatus)) {
      return;
    }

    final clientName = (previous?.clientName ?? '').trim();
    final oldLabel = oldStatus == null
        ? 'status anterior'
        : ProjectStatus.labelFor(oldStatus);
    final newLabel = ProjectStatus.labelFor(nextStatus);
    final reason = (rejectionReason ?? '').trim();
    final reasonText =
        ProjectStatus.rejected.matches(nextStatus) && reason.isNotEmpty
            ? ' ($reason)'
            : '';
    final projectLabel = clientName.isEmpty
        ? 'Projeto #$projectId'
        : 'Projeto #$projectId ($clientName)';

    try {
      await _supabase.from('action_history').insert({
        'action': 'project_status_updated',
        'entity': 'project',
        'detail': '$projectLabel: $oldLabel → $newLabel$reasonText',
      });
    } catch (error) {
      debugPrint('Falha ao registrar historico de status: $error');
    }
  }
}

class _ProjectStatusLogData {
  const _ProjectStatusLogData({
    required this.status,
    required this.clientName,
  });

  final String status;
  final String clientName;

  factory _ProjectStatusLogData.fromMap(Map<String, dynamic> map) {
    final client = map['clients'];
    return _ProjectStatusLogData(
      status: '${map['status'] ?? ''}',
      clientName: client is Map ? '${client['name'] ?? ''}' : '',
    );
  }
}
