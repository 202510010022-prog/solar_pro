import 'package:supabase/supabase.dart';

import 'supabase_test_clients.dart';

Future<void> cleanupFixtures({
  required SupabaseClient serviceRoleClient,
  required SupabaseAdminApi adminApi,
  required String runId,
}) async {
  final companies = await _fixtureCompanies(serviceRoleClient, runId: runId);
  await cleanupCompanies(
    serviceRoleClient: serviceRoleClient,
    adminApi: adminApi,
    companyIds: companies.map((row) => '${row['id']}').toList(),
  );
}

Future<void> cleanupStaleFixtures({
  required SupabaseClient serviceRoleClient,
  required SupabaseAdminApi adminApi,
  Duration olderThan = const Duration(hours: 6),
}) async {
  final cutoff = DateTime.now().toUtc().subtract(olderThan).toIso8601String();
  final rows = await serviceRoleClient
      .from('companies')
      .select('id, name, created_at')
      .like('name', 'rls_test_%')
      .lt('created_at', cutoff);
  final companyIds = (rows as List)
      .map((row) => '${(row as Map)['id']}')
      .where((id) => id.isNotEmpty)
      .toList();
  await cleanupCompanies(
    serviceRoleClient: serviceRoleClient,
    adminApi: adminApi,
    companyIds: companyIds,
  );
}

Future<void> cleanupCompanies({
  required SupabaseClient serviceRoleClient,
  required SupabaseAdminApi adminApi,
  required List<String> companyIds,
}) async {
  if (companyIds.isEmpty) return;

  final profileRows = await serviceRoleClient
      .from('profiles')
      .select('id')
      .inFilter('company_id', companyIds);
  final userIds = (profileRows as List)
      .map((row) => '${(row as Map)['id']}')
      .where((id) => id.isNotEmpty)
      .toList();

  await _deleteByCompany(serviceRoleClient, 'app_messages', companyIds);
  await _deleteByCompany(serviceRoleClient, 'manual_payments', companyIds);
  await _deleteByCompany(serviceRoleClient, 'project_payments', companyIds);
  await _deleteByCompany(serviceRoleClient, 'project_documents', companyIds);
  await _deleteByCompany(serviceRoleClient, 'action_history', companyIds);
  await _deleteByCompany(serviceRoleClient, 'beta_feedback', companyIds);
  await _deleteByCompany(serviceRoleClient, 'projects', companyIds);
  await _deleteByCompany(serviceRoleClient, 'budgets', companyIds);
  await _deleteByCompany(serviceRoleClient, 'clients', companyIds);
  await _deleteByCompany(serviceRoleClient, 'subscriptions', companyIds);
  await _deleteByCompany(serviceRoleClient, 'profiles', companyIds);

  for (final userId in userIds) {
    await adminApi.deleteAuthUser(userId);
  }

  await serviceRoleClient.from('companies').delete().inFilter('id', companyIds);
}

Future<List<Map<String, dynamic>>> _fixtureCompanies(
  SupabaseClient serviceRoleClient, {
  required String runId,
}) async {
  final rows = await serviceRoleClient
      .from('companies')
      .select('id, name')
      .like('name', '$runId%');
  return (rows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();
}

Future<void> _deleteByCompany(
  SupabaseClient serviceRoleClient,
  String table,
  List<String> companyIds,
) async {
  await serviceRoleClient
      .from(table)
      .delete()
      .inFilter('company_id', companyIds);
}
