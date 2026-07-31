import 'dart:math';

import 'package:supabase/supabase.dart';

import 'supabase_test_clients.dart';

class RlsTestFixtures {
  const RlsTestFixtures({
    required this.runId,
    required this.companyA,
    required this.companyB,
  });

  final String runId;
  final FixtureCompany companyA;
  final FixtureCompany companyB;
}

class FixtureCompany {
  const FixtureCompany({
    required this.id,
    required this.name,
    required this.status,
    required this.admin,
    required this.user,
  });

  final String id;
  final String name;
  final String status;
  final FixtureUser admin;
  final FixtureUser user;
}

class FixtureUser {
  const FixtureUser({
    required this.id,
    required this.email,
    required this.password,
    required this.permission,
  });

  final String id;
  final String email;
  final String password;
  final String permission;
}

String newRunId() {
  final now = DateTime.now().toUtc();
  final stamp = now.microsecondsSinceEpoch.toString();
  final random = Random.secure().nextInt(0x1000000).toRadixString(36);
  return 'rls_test_${stamp}_$random';
}

Future<RlsTestFixtures> createBasicRlsFixtures({
  required SupabaseClient serviceRoleClient,
  required SupabaseAdminApi adminApi,
  String? runId,
}) async {
  final id = runId ?? newRunId();
  final password = 'SolarProTest@2026';

  final companyA = await _createCompanyWithUsers(
    serviceRoleClient: serviceRoleClient,
    adminApi: adminApi,
    runId: id,
    suffix: 'a',
    name: '$id Empresa A ativa',
    status: 'active',
    password: password,
  );

  final companyB = await _createCompanyWithUsers(
    serviceRoleClient: serviceRoleClient,
    adminApi: adminApi,
    runId: id,
    suffix: 'b',
    name: '$id Empresa B bloqueada',
    status: 'blocked',
    password: password,
  );

  return RlsTestFixtures(runId: id, companyA: companyA, companyB: companyB);
}

Future<FixtureCompany> createRlsFixtureCompany({
  required SupabaseClient serviceRoleClient,
  required SupabaseAdminApi adminApi,
  required String runId,
  required String suffix,
  required String name,
  required String status,
  String? trialEndsAt,
  String? subscriptionEndsAt,
}) async {
  return _createCompanyWithUsers(
    serviceRoleClient: serviceRoleClient,
    adminApi: adminApi,
    runId: runId,
    suffix: suffix,
    name: name,
    status: status,
    password: 'SolarProTest@2026',
    trialEndsAt: trialEndsAt,
    subscriptionEndsAt: subscriptionEndsAt,
  );
}

Future<FixtureCompany> _createCompanyWithUsers({
  required SupabaseClient serviceRoleClient,
  required SupabaseAdminApi adminApi,
  required String runId,
  required String suffix,
  required String name,
  required String status,
  required String password,
  String? trialEndsAt,
  String? subscriptionEndsAt,
}) async {
  final now = DateTime.now().toUtc();
  final future = now.add(const Duration(days: 30)).toIso8601String();
  final effectiveSubscriptionEndsAt =
      subscriptionEndsAt ?? (status == 'active' ? future : null);

  final companyRow = await serviceRoleClient
      .from('companies')
      .insert({
        'name': name,
        'document': 'RLS-$runId-$suffix',
        'plan': 'equipe',
        'plan_slug': 'equipe',
        'subscription_status': status,
        'trial_ends_at': trialEndsAt,
        'subscription_ends_at': effectiveSubscriptionEndsAt,
        'billing_email': 'billing+$runId.$suffix@solarpro.test',
        'billing_provider': 'manual',
        'billing_notes': 'Fixture de teste RLS $runId.',
        'active': true,
      })
      .select('id, name, subscription_status')
      .single();

  final companyId = '${companyRow['id']}';
  await serviceRoleClient.from('subscriptions').insert({
    'company_id': companyId,
    'plan_slug': 'equipe',
    'status': status,
    'provider': 'manual',
    'current_period_start': now.toIso8601String(),
    'current_period_end': effectiveSubscriptionEndsAt,
    'notes': 'Fixture de teste RLS $runId.',
  });

  final admin = await _createUserProfile(
    serviceRoleClient: serviceRoleClient,
    adminApi: adminApi,
    companyId: companyId,
    email: 'admin_$suffix.$runId@solarpro.test',
    password: password,
    name: '$runId Admin $suffix',
    matricula: '${runId}_admin_$suffix',
    role: 'Diretor',
    permission: 'diretor',
  );

  final user = await _createUserProfile(
    serviceRoleClient: serviceRoleClient,
    adminApi: adminApi,
    companyId: companyId,
    email: 'user_$suffix.$runId@solarpro.test',
    password: password,
    name: '$runId Usuario $suffix',
    matricula: '${runId}_user_$suffix',
    role: 'Assessor de Projetos',
    permission: 'assessor_projetos',
  );

  return FixtureCompany(
    id: companyId,
    name: name,
    status: status,
    admin: admin,
    user: user,
  );
}

Future<FixtureUser> _createUserProfile({
  required SupabaseClient serviceRoleClient,
  required SupabaseAdminApi adminApi,
  required String companyId,
  required String email,
  required String password,
  required String name,
  required String matricula,
  required String role,
  required String permission,
}) async {
  final userId = await adminApi.createAuthUser(
    email: email,
    password: password,
    name: name,
    matricula: matricula,
    role: role,
    permission: permission,
  );

  await serviceRoleClient.from('profiles').insert({
    'id': userId,
    'company_id': companyId,
    'name': name,
    'matricula': matricula,
    'email': email,
    'role': role,
    'permission': permission,
    'active': true,
  });

  return FixtureUser(
    id: userId,
    email: email,
    password: password,
    permission: permission,
  );
}
