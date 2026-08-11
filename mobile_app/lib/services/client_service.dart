import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/client.dart';
import '../models/project.dart';
import 'cache_service.dart';

class ClientService {
  ClientService(
    this._supabase,
    this._cache, {
    required this.currentCompanyId,
    required this.cacheKey,
    required this.ensureCompanyCanWrite,
    required this.loadProjects,
    required this.refreshProjectsInBackground,
  });

  final SupabaseClient _supabase;
  final CacheService _cache;
  final Future<String> Function() currentCompanyId;
  final String Function(String key) cacheKey;
  final Future<void> Function(String action) ensureCompanyCanWrite;
  final Future<List<Project>> Function({bool cacheFirst}) loadProjects;
  final Future<void> Function() refreshProjectsInBackground;

  Future<List<Client>> loadClients({bool cacheFirst = true}) async {
    final companyId = await currentCompanyId();
    final key = cacheKey('clients');
    if (cacheFirst) {
      final cached = await _cache.loadJsonList(key);
      if (cached.isNotEmpty) {
        _refreshClientsInBackground();
        return cached.map(Client.fromMap).toList();
      }
    }

    final rows = await _supabase
        .from('clients')
        .select()
        .eq('company_id', companyId)
        .order('name');
    final data = rows.map((row) => Map<String, dynamic>.from(row)).toList();
    await _cache.saveJsonList(key, data);
    return data.map(Client.fromMap).toList();
  }

  Future<Set<int>> loadClientIdsWithProjects({bool cacheFirst = true}) async {
    final projects = await loadProjects(cacheFirst: cacheFirst);
    return projects
        .map((project) => project.clientId)
        .where((id) => id > 0)
        .toSet();
  }

  Future<void> createClient(Client client, String companyId) async {
    await ensureCompanyCanWrite('cadastrar clientes');
    await _supabase.from('clients').insert(client.toMap(companyId: companyId));
    await _refreshClientsInBackground();
  }

  Future<void> updateClient(Client client) async {
    await ensureCompanyCanWrite('editar clientes');
    final id = client.id;
    if (id == null) throw StateError('Cliente sem ID.');
    await _supabase.from('clients').update(client.toMap()).eq('id', id);
    await _refreshClientsInBackground();
  }

  Future<void> deleteClient(int clientId) async {
    await ensureCompanyCanWrite('excluir clientes');
    await _supabase.from('clients').delete().eq('id', clientId);
    await _refreshClientsInBackground();
    await refreshProjectsInBackground();
  }

  Future<CepLookupResult> lookupCep(String cep) async {
    try {
      final response = await _supabase.functions.invoke(
        'cep-lookup',
        body: {'cep': cep},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['error'] != null) throw StateError('${data['error']}');
        return CepLookupResult.fromMap(data);
      }
      if (data is Map) {
        final mapped = Map<String, dynamic>.from(data);
        if (mapped['error'] != null) throw StateError('${mapped['error']}');
        return CepLookupResult.fromMap(mapped);
      }
      throw StateError('Resposta inválida da consulta de CEP.');
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        throw StateError('${details['error']}');
      }
      throw StateError(error.reasonPhrase ?? 'Não foi possível consultar CEP.');
    }
  }

  Future<void> _refreshClientsInBackground() async {
    try {
      final companyId = await currentCompanyId();
      final rows = await _supabase
          .from('clients')
          .select()
          .eq('company_id', companyId)
          .order('name');
      await _cache.saveJsonList(
        cacheKey('clients'),
        rows.map((row) => Map<String, dynamic>.from(row)).toList(),
      );
    } catch (_) {
      // Offline-first: cache remains valid when network is unavailable.
    }
  }
}

class CepLookupResult {
  const CepLookupResult({
    required this.zipCode,
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.source,
    this.addressResolution,
  });

  final String zipCode;
  final String street;
  final String neighborhood;
  final String city;
  final String state;
  final String source;
  final String? addressResolution;

  factory CepLookupResult.fromMap(Map<String, dynamic> map) {
    return CepLookupResult(
      zipCode: '${map['zip_code'] ?? ''}',
      street: '${map['street'] ?? ''}',
      neighborhood: '${map['neighborhood'] ?? ''}',
      city: '${map['city'] ?? ''}',
      state: '${map['state'] ?? ''}',
      source: '${map['source'] ?? ''}',
      addressResolution: _nullableString(map['address_resolution']),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final raw = '$value'.trim();
    return raw.isEmpty || raw == 'null' ? null : raw;
  }
}
