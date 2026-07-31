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

  group('bloqueio de escrita por status da empresa', () {
    test('empresa ativa consegue criar cliente', () async {
      final client = await clients.signInAs(fixtures.companyA.user);

      final created = await _createClient(
        client,
        companyId: fixtures.companyA.id,
        name: '${fixtures.runId} Cliente ativo',
      );

      expect(created['id'], isNotNull);
      expect(created['company_id'], fixtures.companyA.id);
      expect(created['name'], '${fixtures.runId} Cliente ativo');
    });

    test('empresa ativa consegue criar projeto', () async {
      final client = await clients.signInAs(fixtures.companyA.user);
      final createdClient = await _createClient(
        client,
        companyId: fixtures.companyA.id,
        name: '${fixtures.runId} Cliente projeto ativo',
      );

      final project = await _createProject(
        client,
        companyId: fixtures.companyA.id,
        clientId: createdClient['id'] as int,
        status: 'Em negociação',
      );

      expect(project['id'], isNotNull);
      expect(project['company_id'], fixtures.companyA.id);
      expect(project['client_id'], createdClient['id']);
    });

    test('empresa bloqueada NÃO consegue criar cliente', () async {
      final client = await clients.signInAs(fixtures.companyB.user);

      await expectLater(
        () => _createClient(
          client,
          companyId: fixtures.companyB.id,
          name: '${fixtures.runId} Cliente bloqueado',
        ),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('empresa bloqueada NÃO consegue criar projeto', () async {
      final blockedClient = await serviceRoleClient
          .from('clients')
          .insert({
            'company_id': fixtures.companyB.id,
            'name': '${fixtures.runId} Cliente preexistente bloqueado',
            'document': '',
            'phone': '',
            'email': '',
          })
          .select('id')
          .single();
      final client = await clients.signInAs(fixtures.companyB.user);

      await expectLater(
        () => _createProject(
          client,
          companyId: fixtures.companyB.id,
          clientId: blockedClient['id'] as int,
          status: 'Em negociação',
        ),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('empresa bloqueada ainda consegue LER seus próprios dados', () async {
      final existingClient = await serviceRoleClient
          .from('clients')
          .insert({
            'company_id': fixtures.companyB.id,
            'name': '${fixtures.runId} Cliente leitura bloqueada',
            'document': '',
            'phone': '',
            'email': '',
          })
          .select('id, name')
          .single();
      final existingProject = await serviceRoleClient
          .from('projects')
          .insert({
            'company_id': fixtures.companyB.id,
            'client_id': existingClient['id'],
            'project_date': '2026-07-31',
            'status': 'Em negociação',
          })
          .select('id')
          .single();

      final client = await clients.signInAs(fixtures.companyB.user);
      final readableClients = await client
          .from('clients')
          .select('id, name, company_id')
          .eq('id', existingClient['id'] as int);
      final readableProjects = await client
          .from('projects')
          .select('id, client_id, company_id')
          .eq('id', existingProject['id'] as int);

      expect(readableClients, hasLength(1));
      expect(readableClients.first['company_id'], fixtures.companyB.id);
      expect(readableProjects, hasLength(1));
      expect(readableProjects.first['company_id'], fixtures.companyB.id);
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

Future<Map<String, dynamic>> _createProject(
  SupabaseClient client, {
  required String companyId,
  required int clientId,
  required String status,
}) async {
  final row = await client
      .from('projects')
      .insert({
        'company_id': companyId,
        'client_id': clientId,
        'project_date': '2026-07-31',
        'status': status,
      })
      .select('id, company_id, client_id')
      .single();
  return Map<String, dynamic>.from(row as Map);
}
