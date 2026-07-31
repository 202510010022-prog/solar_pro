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
  late FixtureCompany expiredActiveCompany;

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

    final expiredAt = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 2))
        .toIso8601String();
    expiredActiveCompany = await createRlsFixtureCompany(
      serviceRoleClient: serviceRoleClient,
      adminApi: adminApi,
      runId: fixtures.runId,
      suffix: 'c',
      name: '${fixtures.runId} Empresa C ativa vencida',
      status: 'active',
      subscriptionEndsAt: expiredAt,
    );
  });

  tearDownAll(() async {
    await cleanupFixtures(
      serviceRoleClient: serviceRoleClient,
      adminApi: adminApi,
      runId: fixtures.runId,
    );
  });

  Future<Map<String, dynamic>> createManualPaymentAsServiceRole({
    required String companyId,
    required String notes,
  }) async {
    final row = await serviceRoleClient
        .from('manual_payments')
        .insert({
          'company_id': companyId,
          'amount': 150,
          'currency': 'BRL',
          'due_date': '2026-08-10',
          'status': 'pending',
          'pix_reference': 'pix-${fixtures.runId}',
          'notes': notes,
        })
        .select('id, company_id, notes')
        .single();
    return Map<String, dynamic>.from(row as Map);
  }

  group('assinatura e visibilidade de cobrancas', () {
    test(
        'empresa ativa mas com subscription_ends_at vencido NÃO consegue escrever',
        () async {
      final client = await clients.signInAs(expiredActiveCompany.user);

      await expectLater(
        () => _createClient(
          client,
          companyId: expiredActiveCompany.id,
          name: '${fixtures.runId} Cliente empresa ativa vencida',
        ),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('empresa ativa com subscription_ends_at no futuro consegue escrever',
        () async {
      final client = await clients.signInAs(fixtures.companyA.user);

      final created = await _createClient(
        client,
        companyId: fixtures.companyA.id,
        name: '${fixtures.runId} Cliente assinatura futura',
      );

      expect(created['id'], isNotNull);
      expect(created['company_id'], fixtures.companyA.id);
    });

    test('usuário comum NÃO consegue ler manual_payments da própria empresa',
        () async {
      final payment = await createManualPaymentAsServiceRole(
        companyId: fixtures.companyA.id,
        notes: '${fixtures.runId} Cobranca usuario comum',
      );
      final client = await clients.signInAs(fixtures.companyA.user);

      final visiblePayments = await client
          .from('manual_payments')
          .select('id, company_id, notes')
          .eq('id', payment['id'] as int);

      expect(visiblePayments, isEmpty);
    });

    test('admin CONSEGUE ler manual_payments da própria empresa', () async {
      final payment = await createManualPaymentAsServiceRole(
        companyId: fixtures.companyA.id,
        notes: '${fixtures.runId} Cobranca admin',
      );
      final client = await clients.signInAs(fixtures.companyA.admin);

      final visiblePayments = await client
          .from('manual_payments')
          .select('id, company_id, notes')
          .eq('id', payment['id'] as int);

      expect(visiblePayments, hasLength(1));
      expect(visiblePayments.first['company_id'], fixtures.companyA.id);
      expect(visiblePayments.first['notes'], payment['notes']);
    });

    test(
        'usuário de uma empresa não vê manual_payments de outra empresa nem sendo admin',
        () async {
      final companyAPayment = await createManualPaymentAsServiceRole(
        companyId: fixtures.companyA.id,
        notes: '${fixtures.runId} Cobranca privada Empresa A',
      );
      final companyBPayment = await createManualPaymentAsServiceRole(
        companyId: fixtures.companyB.id,
        notes: '${fixtures.runId} Cobranca propria Empresa B',
      );
      final companyBAdminClient =
          await clients.signInAs(fixtures.companyB.admin);

      final visibleCompanyAPayments = await companyBAdminClient
          .from('manual_payments')
          .select('id, company_id, notes')
          .eq('id', companyAPayment['id'] as int);
      final visibleCompanyBPayments = await companyBAdminClient
          .from('manual_payments')
          .select('id, company_id, notes')
          .eq('id', companyBPayment['id'] as int);

      expect(visibleCompanyAPayments, isEmpty);
      expect(visibleCompanyBPayments, hasLength(1));
      expect(visibleCompanyBPayments.first['company_id'], fixtures.companyB.id);
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
