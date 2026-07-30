import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_profile.dart';
import '../models/app_message.dart';
import '../models/app_subscription.dart';
import '../models/beta_feedback.dart';
import '../models/client.dart';
import '../models/manual_payment.dart';
import '../models/project.dart';
import '../models/project_payment.dart';
import '../models/team_invite_result.dart';
import 'auth_service.dart';
import 'cache_service.dart';
import 'client_service.dart';
import 'project_service.dart';
import 'pvgis_validation_service.dart';
import 'sizing_service.dart';

class SolarProRepository {
  SolarProRepository(this._supabase, this._cache) {
    _auth = AuthService(_supabase, _cache, () => _cacheScopePrefix);
    _projects = ProjectService(
      _supabase,
      _cache,
      currentCompanyId: _currentCompanyId,
      currentUserId: () => currentUser?.id,
      cacheKey: _cacheKey,
      ensureCompanyCanWrite: _ensureCompanyCanWrite,
    );
    _clients = ClientService(
      _supabase,
      _cache,
      currentCompanyId: _currentCompanyId,
      cacheKey: _cacheKey,
      ensureCompanyCanWrite: _ensureCompanyCanWrite,
      loadProjects: loadProjects,
      refreshProjectsInBackground: _refreshProjectsInBackground,
    );
  }

  final SupabaseClient _supabase;
  final CacheService _cache;
  late final AuthService _auth;
  late final ProjectService _projects;
  late final ClientService _clients;

  User? get currentUser => _auth.currentUser;

  Stream<AuthState> get authChanges => _auth.authChanges;

  String get _cacheScopePrefix {
    final userId = currentUser?.id ?? 'anonymous';
    return 'user:$userId:';
  }

  String _cacheKey(String key) => '$_cacheScopePrefix$key';

  Future<String> _currentCompanyId() async {
    final profile = await loadProfile();
    return profile.companyId;
  }

  Future<void> signIn(String email, String password) =>
      _auth.signIn(email, password);

  Future<void> signOut() => _auth.signOut();

  Future<AppProfile> loadProfile() => _auth.loadProfile();

  Future<List<AppProfile>> loadTeamProfiles() async {
    final companyId = await _currentCompanyId();
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

  Future<AppSubscription> loadSubscription({bool cacheFirst = true}) async {
    final key = _cacheKey('subscription');
    if (cacheFirst) {
      final cached = await _cache.loadJsonList(key);
      if (cached.isNotEmpty) {
        _refreshSubscriptionInBackground();
        return AppSubscription.fromMap(cached.first);
      }
    }

    final row = await _supabase
        .from('company_billing_overview')
        .select()
        .eq('company_id', await _currentCompanyId())
        .limit(1)
        .single();
    final data = Map<String, dynamic>.from(row);
    await _cache.saveJsonList(key, [data]);
    return AppSubscription.fromMap(data);
  }

  Future<SubscriptionValidation> validateProjectCreation({
    AppSubscription? cachedSubscription,
  }) async {
    final writeValidation = await validateCompanyWriteAccess(
      cachedSubscription: cachedSubscription,
    );
    if (!writeValidation.allowed) return writeValidation;

    final subscription =
        cachedSubscription ?? await loadSubscription(cacheFirst: false);

    final monthlyLimit = subscription.maxProjectsPerMonth;
    if (monthlyLimit == null) {
      return const SubscriptionValidation.allowed();
    }

    final projects = await loadProjects(cacheFirst: false);
    final now = DateTime.now();
    final createdThisMonth = projects.where((project) {
      final date = DateTime.tryParse(project.projectDate);
      return date != null && date.year == now.year && date.month == now.month;
    }).length;

    if (createdThisMonth >= monthlyLimit) {
      return SubscriptionValidation.blocked(
        'Limite mensal do plano ${subscription.planName} atingido: $monthlyLimit projetos por mês.',
      );
    }

    return const SubscriptionValidation.allowed();
  }

  Future<SubscriptionValidation> validateCompanyWriteAccess({
    AppSubscription? cachedSubscription,
    String action = 'realizar esta ação',
  }) async {
    final subscription =
        cachedSubscription ?? await loadSubscription(cacheFirst: false);
    if (subscription.isActive) return const SubscriptionValidation.allowed();

    return SubscriptionValidation.blocked(
      'Empresa ${subscription.statusLabel.toLowerCase()}. Regularize o plano para $action.',
    );
  }

  Future<void> _ensureCompanyCanWrite(String action) async {
    final validation = await validateCompanyWriteAccess(action: action);
    if (!validation.allowed) {
      throw StateError(validation.message ?? 'Empresa bloqueada.');
    }
  }

  Future<List<Client>> loadClients({bool cacheFirst = true}) =>
      _clients.loadClients(cacheFirst: cacheFirst);

  Future<List<Project>> loadProjects({bool cacheFirst = true}) =>
      _projects.loadProjects(cacheFirst: cacheFirst);

  Future<Set<int>> loadClientIdsWithProjects({bool cacheFirst = true}) =>
      _clients.loadClientIdsWithProjects(cacheFirst: cacheFirst);

  Future<void> createClient(Client client, String companyId) =>
      _clients.createClient(client, companyId);

  Future<void> updateClient(Client client) => _clients.updateClient(client);

  Future<void> deleteClient(int clientId) => _clients.deleteClient(clientId);

  Future<CepLookupResult> lookupCep(String cep) => _clients.lookupCep(cep);

  Future<void> updateProjectStatus(int projectId, String status) =>
      _projects.updateProjectStatus(projectId, status);

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
  }) =>
      _projects.updateProjectSummary(
        projectId: projectId,
        status: status,
        projectValue: projectValue,
        laborCost: laborCost,
        moduleUnitCost: moduleUnitCost,
        inverterCost: inverterCost,
        supportCost: supportCost,
        extraMaterials: extraMaterials,
        energyTariff: energyTariff,
        modulePower: modulePower,
        paybackYears: paybackYears,
      );

  Future<void> updateProjectFinancialPlan({
    required int projectId,
    required String paymentType,
    required double downPayment,
    required double discount,
    required int installmentsCount,
    required double installmentValue,
    required DateTime? firstDueDate,
    required String notes,
  }) async {
    await _ensureCompanyCanWrite('editar financeiro do projeto');
    await _supabase.from('projects').update({
      'payment_type': paymentType.trim(),
      'down_payment': downPayment,
      'discount': discount,
      'installments_count': installmentsCount,
      'installment_value': installmentValue,
      'first_due_date': firstDueDate?.toIso8601String().split('T').first,
      'financial_notes': notes.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', projectId);
    await _refreshProjectsInBackground();
  }

  Future<void> deleteProject(int projectId) =>
      _projects.deleteProject(projectId);

  Future<List<ProjectPayment>> loadProjectPayments({
    bool cacheFirst = true,
  }) async {
    final companyId = await _currentCompanyId();
    final rows = await _supabase
        .from('project_payments')
        .select()
        .eq('company_id', companyId)
        .neq('status', 'canceled')
        .order('paid_at', ascending: false);
    return rows
        .map((row) => ProjectPayment.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> createProjectPayment({
    required int projectId,
    required double amount,
    required String paymentType,
    required DateTime paidAt,
    required String notes,
  }) async {
    await _ensureCompanyCanWrite('registrar pagamentos de clientes');
    final companyId = await _currentCompanyId();
    await _supabase.from('project_payments').insert({
      'company_id': companyId,
      'project_id': projectId,
      'amount': amount,
      'payment_type': paymentType.trim(),
      'paid_at': paidAt.toIso8601String(),
      'status': 'paid',
      'notes': notes.trim(),
      'created_by': currentUser?.id,
    });
  }

  Future<void> cancelProjectPayment(int paymentId) async {
    await _ensureCompanyCanWrite('cancelar pagamentos de clientes');
    final companyId = await _currentCompanyId();
    await _supabase
        .from('project_payments')
        .update({
          'status': 'canceled',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', paymentId)
        .eq('company_id', companyId);
  }

  Future<void> createFollowUpMessage(Project project) =>
      _projects.createFollowUpMessage(project);

  Future<PvgisValidationResult> validateWithPvgis({
    required Client client,
    required double installedPowerKwp,
    required double estimatedAnnualGeneration,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'pvgis-validate',
        body: {
          if (latitude != null && longitude != null) ...{
            'latitude': latitude,
            'longitude': longitude,
          } else
            'address': {
              'zip_code': client.zipCode,
              'street': client.street,
              'address_number': client.addressNumber,
              'neighborhood': client.neighborhood,
              'city': client.city,
              'state': client.state,
            },
          'installed_power_kwp': installedPowerKwp,
          'estimated_annual_generation': estimatedAnnualGeneration,
          'system_loss_percent': 14,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['error'] != null) throw StateError('${data['error']}');
        return PvgisValidationResult.fromMap(data);
      }
      if (data is Map) {
        final mapped = Map<String, dynamic>.from(data);
        if (mapped['error'] != null) throw StateError('${mapped['error']}');
        return PvgisValidationResult.fromMap(mapped);
      }
      throw StateError('Resposta invalida do PVGIS.');
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        throw StateError('${details['error']}');
      }
      throw StateError(error.reasonPhrase ?? 'Falha ao validar com PVGIS.');
    }
  }

  Future<PvgisValidationResult> lookupMonthlyHspWithPvgis({
    required Client client,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'pvgis-validate',
        body: {
          'mode': 'hsp_lookup',
          'address': {
            'zip_code': client.zipCode,
            'street': client.street,
            'address_number': client.addressNumber,
            'neighborhood': client.neighborhood,
            'city': client.city,
            'state': client.state,
          },
          'installed_power_kwp': 1,
          'estimated_annual_generation': 1,
          'system_loss_percent': 14,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['error'] != null) throw StateError('${data['error']}');
        return PvgisValidationResult.fromMap(data);
      }
      if (data is Map) {
        final mapped = Map<String, dynamic>.from(data);
        if (mapped['error'] != null) throw StateError('${mapped['error']}');
        return PvgisValidationResult.fromMap(mapped);
      }
      throw StateError('Resposta invalida do PVGIS.');
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        throw StateError('${details['error']}');
      }
      throw StateError(error.reasonPhrase ?? 'Falha ao buscar HSP no PVGIS.');
    }
  }

  Future<void> createSizingProject({
    required int clientId,
    required String companyId,
    required List<double> monthlyConsumption,
    required List<double> monthlyHsp,
    required double generationExtraPercent,
    required double performanceRatio,
    required double modulePower,
    required double tariff,
    required double projectValue,
    required double laborCost,
    required double moduleUnitCost,
    required double inverterCost,
    required double supportCost,
    required List<Map<String, dynamic>> extraMaterials,
    required SizingResult result,
  }) async {
    final creationValidation = await validateProjectCreation();
    if (!creationValidation.allowed) {
      throw StateError(creationValidation.message ?? 'Empresa bloqueada.');
    }
    final currentCompanyId = await _currentCompanyId();
    if (companyId != currentCompanyId) {
      throw StateError('Empresa do projeto diferente da sessão atual.');
    }
    await _supabase.from('projects').insert({
      'company_id': companyId,
      'client_id': clientId,
      'project_date': DateTime.now().toIso8601String().split('T').first,
      'status': 'Em negociação',
      'monthly_consumption': result.averageConsumption,
      'sun_hours': result.averageHsp,
      'monthly_consumptions': jsonEncode(monthlyConsumption),
      'monthly_hsp': jsonEncode(monthlyHsp),
      'monthly_generations': jsonEncode(result.monthlyGenerations),
      'monthly_balances': jsonEncode(result.monthlyBalances),
      'generation_extra_percent': generationExtraPercent,
      'average_consumption': result.averageConsumption,
      'average_hsp': result.averageHsp,
      'annual_consumption': result.annualConsumption,
      'annual_generation': result.annualGeneration,
      'performance_ratio': performanceRatio,
      'module_power': modulePower,
      'energy_tariff': tariff,
      'project_value': projectValue,
      'labor_cost': laborCost,
      'module_unit_cost': moduleUnitCost,
      'inverter_cost': inverterCost,
      'support_cost': supportCost,
      'extra_materials': jsonEncode(extraMaterials),
      'system_power': result.systemPower,
      'module_count': result.moduleCount,
      'monthly_generation': result.monthlyGeneration,
      'monthly_savings': result.monthlySavings,
      'payback_years': result.paybackYears,
      'history': jsonEncode([
        {
          'action': 'created_mobile',
          'detail': 'Projeto criado pelo aplicativo mobile.',
          'created_at': DateTime.now().toIso8601String(),
        }
      ]),
    });

    await _refreshProjectsInBackground();
  }

  Future<void> submitBetaFeedback({
    required String companyId,
    required int rating,
    required String area,
    required String message,
  }) async {
    await _ensureCompanyCanWrite('enviar feedback');
    await _supabase.from('beta_feedback').insert({
      'company_id': companyId,
      'profile_id': currentUser?.id,
      'rating': rating,
      'area': area,
      'message': message.trim(),
      'app_version': 'Solar Pro Mobile 0.1.0',
    });
  }

  Future<TeamInviteResult> inviteTeamUser({
    required String name,
    required String email,
    required String matricula,
    required String permission,
    required String role,
    String password = '',
  }) async {
    await _ensureCompanyCanWrite('convidar usuários');
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
    await _ensureCompanyCanWrite('editar usuários');
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
    await _ensureCompanyCanWrite('excluir usuários');
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

  Future<List<BetaFeedback>> loadBetaFeedback() async {
    final companyId = await _currentCompanyId();
    final rows = await _supabase
        .from('beta_feedback')
        .select('*, profiles(name)')
        .eq('company_id', companyId)
        .order('created_at', ascending: false)
        .limit(30);
    return rows
        .map((row) => BetaFeedback.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> updateBetaFeedbackStatus(int feedbackId, String status) async {
    await _ensureCompanyCanWrite('alterar feedbacks');
    await _supabase.from('beta_feedback').update({
      'status': status,
      'resolved_at':
          status == 'resolved' ? DateTime.now().toIso8601String() : null,
    }).eq('id', feedbackId);
  }

  Future<List<AppMessage>> loadAppMessages({bool unreadOnly = false}) async {
    final companyId = await _currentCompanyId();
    final rows = unreadOnly
        ? await _supabase
            .from('app_messages')
            .select()
            .eq('company_id', companyId)
            .eq('status', 'unread')
            .order('created_at', ascending: false)
            .limit(50)
        : await _supabase
            .from('app_messages')
            .select()
            .eq('company_id', companyId)
            .neq('status', 'archived')
            .order('created_at', ascending: false)
            .limit(50);

    return rows
        .map((row) => AppMessage.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> markAppMessageRead(int messageId) async {
    await _ensureCompanyCanWrite('alterar mensagens');
    await _supabase.from('app_messages').update({
      'status': 'read',
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  Future<void> archiveAppMessage(int messageId) async {
    await _ensureCompanyCanWrite('arquivar mensagens');
    await _supabase.from('app_messages').update({
      'status': 'archived',
    }).eq('id', messageId);
  }

  Future<List<ManualPayment>> loadManualPayments() async {
    final companyId = await _currentCompanyId();
    final rows = await _supabase
        .from('manual_payments')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
    return rows
        .map((row) => ManualPayment.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<ManualPayment>> loadOpenManualPayments() async {
    final companyId = await _currentCompanyId();
    final rows = await _supabase
        .from('manual_payments')
        .select()
        .eq('company_id', companyId)
        .inFilter('status', ['pending', 'overdue'])
        .order('due_date')
        .limit(5);
    return rows
        .map((row) => ManualPayment.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> createManualPayment({
    required double amount,
    required DateTime dueDate,
    required String pixReference,
    required String notes,
  }) async {
    await _ensureCompanyCanWrite('criar cobranças');
    await _invokePaymentAction({
      'action': 'create',
      'amount': amount,
      'due_date': dueDate.toIso8601String().split('T').first,
      'pix_reference': pixReference.trim(),
      'notes': notes.trim(),
    });
  }

  Future<void> markManualPaymentPaid(int paymentId,
      {int periodMonths = 1}) async {
    await _ensureCompanyCanWrite('confirmar cobranças');
    await _invokePaymentAction({
      'action': 'mark_paid',
      'payment_id': paymentId,
      'period_months': periodMonths,
    });
    await _refreshSubscriptionInBackground();
  }

  Future<void> cancelManualPayment(int paymentId) async {
    await _ensureCompanyCanWrite('cancelar cobranças');
    await _invokePaymentAction({
      'action': 'cancel',
      'payment_id': paymentId,
    });
  }

  Future<void> syncOverdueManualPayments() async {
    await _invokePaymentAction({'action': 'sync_overdue'});
  }

  Future<void> _invokePaymentAction(Map<String, dynamic> body) async {
    try {
      await _supabase.functions.invoke('manage-payment', body: body);
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        throw StateError('${details['error']}');
      }
      throw StateError(
          error.reasonPhrase ?? 'Nao foi possivel processar cobranca.');
    }
  }

  Future<void> _refreshProjectsInBackground() =>
      _projects.refreshProjectsInBackground();

  Future<void> _refreshSubscriptionInBackground() async {
    try {
      final row = await _supabase
          .from('company_billing_overview')
          .select()
          .eq('company_id', await _currentCompanyId())
          .limit(1)
          .single();
      await _cache.saveJsonList(
        _cacheKey('subscription'),
        [Map<String, dynamic>.from(row)],
      );
    } catch (_) {
      // Offline-first: cache remains valid when network is unavailable.
    }
  }
}
