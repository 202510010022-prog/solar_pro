import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

import 'package:solarpro_integration_tests/cleanup.dart';
import 'package:solarpro_integration_tests/supabase_test_clients.dart';
import 'package:solarpro_integration_tests/test_env.dart';
import 'package:solarpro_integration_tests/test_fixtures.dart';

void main() {
  late TestEnv env;
  late SupabaseTestClients clients;
  late SupabaseClient serviceRoleClient;
  late SupabaseAdminApi adminApi;
  late RlsTestFixtures fixtures;

  setUpAll(() async {
    env = await TestEnv.load(path: '.env');
    clients = SupabaseTestClients(env);
    serviceRoleClient = clients.serviceRoleClient;
    adminApi = SupabaseAdminApi(env);

    await cleanupStaleFixtures(
      serviceRoleClient: serviceRoleClient,
      adminApi: adminApi,
    );

    fixtures = await createBasicRlsFixtures(
      serviceRoleClient: serviceRoleClient,
      adminApi: adminApi,
    );
  });

  tearDownAll(() async {
    await cleanupFixtures(
      serviceRoleClient: serviceRoleClient,
      adminApi: adminApi,
      runId: fixtures.runId,
    );
  });

  Future<Map<String, dynamic>> createClientAsServiceRole({
    required String companyId,
    required String name,
  }) async {
    final row = await serviceRoleClient
        .from('clients')
        .insert({
          'company_id': companyId,
          'name': name,
          'document': '',
          'phone': '',
          'email': '',
        })
        .select('id, company_id, name')
        .single();
    return Map<String, dynamic>.from(row as Map);
  }

  Future<Map<String, dynamic>> createProjectAsServiceRole({
    required String companyId,
    required int clientId,
  }) async {
    final row = await serviceRoleClient
        .from('projects')
        .insert({
          'company_id': companyId,
          'client_id': clientId,
          'project_date': '2026-07-31',
          'status': 'Em negociação',
        })
        .select('id, company_id, client_id')
        .single();
    return Map<String, dynamic>.from(row as Map);
  }

  Future<Map<String, dynamic>> createProjectPaymentAsServiceRole({
    required String companyId,
    required int projectId,
  }) async {
    final row = await serviceRoleClient
        .from('project_payments')
        .insert({
          'company_id': companyId,
          'project_id': projectId,
          'amount': 100,
          'payment_type': 'pix',
          'status': 'paid',
          'notes': 'Fixture isolamento multi-tenant ${fixtures.runId}',
        })
        .select('id, company_id, project_id')
        .single();
    return Map<String, dynamic>.from(row as Map);
  }

  group('isolamento multi-tenant', () {
    test('usuário da Empresa A não vê clientes da Empresa B', () async {
      final companyAClient = await clients.signInAs(fixtures.companyA.user);
      final companyBClient = await clients.signInAs(fixtures.companyB.user);
      final created = await _createClient(
        companyAClient,
        companyId: fixtures.companyA.id,
        name: '${fixtures.runId} Cliente privado Empresa A',
      );

      final visibleToCompanyB = await companyBClient
          .from('clients')
          .select('id, company_id, name')
          .eq('id', created['id'] as int);

      expect(visibleToCompanyB, isEmpty);
    });

    test('usuário da Empresa A não consegue editar cliente da Empresa B',
        () async {
      final companyBClientRow = await createClientAsServiceRole(
        companyId: fixtures.companyB.id,
        name: '${fixtures.runId} Cliente protegido Empresa B',
      );
      final companyAClient = await clients.signInAs(fixtures.companyA.user);

      final updated = await companyAClient
          .from('clients')
          .update({'name': '${fixtures.runId} Tentativa invasiva'})
          .eq('id', companyBClientRow['id'] as int)
          .select('id');
      final reloaded = await serviceRoleClient
          .from('clients')
          .select('name')
          .eq('id', companyBClientRow['id'] as int)
          .single();

      expect(updated, isEmpty);
      expect(reloaded['name'], companyBClientRow['name']);
    });

    test('usuário da Empresa A não consegue deletar cliente da Empresa B',
        () async {
      final companyBClientRow = await createClientAsServiceRole(
        companyId: fixtures.companyB.id,
        name: '${fixtures.runId} Cliente delete protegido Empresa B',
      );
      final companyAClient = await clients.signInAs(fixtures.companyA.user);

      final deleted = await companyAClient
          .from('clients')
          .delete()
          .eq('id', companyBClientRow['id'] as int)
          .select('id');
      final stillExists = await serviceRoleClient
          .from('clients')
          .select('id')
          .eq('id', companyBClientRow['id'] as int);

      expect(deleted, isEmpty);
      expect(stillExists, hasLength(1));
    });

    test('usuário da Empresa A não vê projetos da Empresa B', () async {
      final companyBClientRow = await createClientAsServiceRole(
        companyId: fixtures.companyB.id,
        name: '${fixtures.runId} Cliente projeto privado Empresa B',
      );
      final companyBProject = await createProjectAsServiceRole(
        companyId: fixtures.companyB.id,
        clientId: companyBClientRow['id'] as int,
      );
      final companyAClient = await clients.signInAs(fixtures.companyA.user);

      final visibleToCompanyA = await companyAClient
          .from('projects')
          .select('id, company_id, client_id')
          .eq('id', companyBProject['id'] as int);

      expect(visibleToCompanyA, isEmpty);
    });

    test('usuário da Empresa A não vê pagamentos de projeto da Empresa B',
        () async {
      final companyBClientRow = await createClientAsServiceRole(
        companyId: fixtures.companyB.id,
        name: '${fixtures.runId} Cliente pagamento privado Empresa B',
      );
      final companyBProject = await createProjectAsServiceRole(
        companyId: fixtures.companyB.id,
        clientId: companyBClientRow['id'] as int,
      );
      final companyBPayment = await createProjectPaymentAsServiceRole(
        companyId: fixtures.companyB.id,
        projectId: companyBProject['id'] as int,
      );
      final companyAClient = await clients.signInAs(fixtures.companyA.user);

      final visibleToCompanyA = await companyAClient
          .from('project_payments')
          .select('id, company_id, project_id')
          .eq('id', companyBPayment['id'] as int);

      expect(visibleToCompanyA, isEmpty);
    });
  });
}

Future<Map<String, dynamic>> _createClient(
  SupabaseClient client, {
  required String companyId,
  required String name,
}) async {
  final row = await client
      .from('clients')
      .insert({
        'company_id': companyId,
        'name': name,
        'document': '',
        'phone': '',
        'email': '',
      })
      .select('id, company_id, name')
      .single();
  return Map<String, dynamic>.from(row as Map);
}
