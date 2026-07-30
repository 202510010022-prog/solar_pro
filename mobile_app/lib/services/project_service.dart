import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project.dart';
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

  Future<void> updateProjectStatus(int projectId, String status) async {
    await ensureCompanyCanWrite('alterar projetos');
    await _supabase.from('projects').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', projectId);
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
  }) async {
    await ensureCompanyCanWrite('editar projetos');
    await _supabase.from('projects').update({
      'status': status,
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
}
