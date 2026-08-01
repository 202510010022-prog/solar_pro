import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_profile.dart';
import '../models/app_message.dart';
import '../models/app_subscription.dart';
import '../models/beta_feedback.dart';
import '../models/client.dart';
import '../models/manual_payment.dart';
import '../models/project.dart';
import '../models/project_address.dart';
import '../models/project_payment.dart';
import '../models/team_invite_result.dart';
import 'auth_service.dart';
import 'billing_service.dart';
import 'cache_service.dart';
import 'client_service.dart';
import 'company_service.dart';
import 'feedback_service.dart';
import 'message_service.dart';
import 'project_finance_service.dart';
import 'project_service.dart';
import 'pvgis_validation_service.dart';
import 'sizing_repository_service.dart';
import 'sizing_service.dart';
import 'team_service.dart';

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
    _company = CompanyService(
      _supabase,
      _cache,
      currentCompanyId: _currentCompanyId,
      cacheKey: _cacheKey,
      loadProjects: loadProjects,
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
    _sizing = SizingRepositoryService(
      _supabase,
      currentCompanyId: _currentCompanyId,
      validateProjectCreation: validateProjectCreation,
      refreshProjectsInBackground: _refreshProjectsInBackground,
    );
    _projectFinance = ProjectFinanceService(
      _supabase,
      currentCompanyId: _currentCompanyId,
      currentUserId: () => currentUser?.id,
      ensureCompanyCanWrite: _ensureCompanyCanWrite,
      refreshProjectsInBackground: _refreshProjectsInBackground,
    );
    _billing = BillingService(
      _supabase,
      currentCompanyId: _currentCompanyId,
      ensureCompanyCanWrite: _ensureCompanyCanWrite,
      refreshSubscriptionInBackground: _refreshSubscriptionInBackground,
    );
    _team = TeamService(
      _supabase,
      currentCompanyId: _currentCompanyId,
      ensureCompanyCanWrite: _ensureCompanyCanWrite,
    );
    _messages = MessageService(
      _supabase,
      currentCompanyId: _currentCompanyId,
      ensureCompanyCanWrite: _ensureCompanyCanWrite,
    );
    _feedback = FeedbackService(
      _supabase,
      currentCompanyId: _currentCompanyId,
      currentUserId: () => currentUser?.id,
      ensureCompanyCanWrite: _ensureCompanyCanWrite,
    );
  }

  final SupabaseClient _supabase;
  final CacheService _cache;
  late final AuthService _auth;
  late final ProjectService _projects;
  late final CompanyService _company;
  late final ClientService _clients;
  late final SizingRepositoryService _sizing;
  late final ProjectFinanceService _projectFinance;
  late final BillingService _billing;
  late final TeamService _team;
  late final MessageService _messages;
  late final FeedbackService _feedback;

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

  Future<List<AppProfile>> loadTeamProfiles() => _team.loadTeamProfiles();

  Future<AppSubscription> loadSubscription({bool cacheFirst = true}) =>
      _company.loadSubscription(cacheFirst: cacheFirst);

  Future<SubscriptionValidation> validateProjectCreation({
    AppSubscription? cachedSubscription,
  }) =>
      _company.validateProjectCreation(
        cachedSubscription: cachedSubscription,
      );

  Future<SubscriptionValidation> validateCompanyWriteAccess({
    AppSubscription? cachedSubscription,
    String action = 'realizar esta ação',
  }) =>
      _company.validateCompanyWriteAccess(
        cachedSubscription: cachedSubscription,
        action: action,
      );

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
  }) =>
      _projectFinance.updateProjectFinancialPlan(
        projectId: projectId,
        paymentType: paymentType,
        downPayment: downPayment,
        discount: discount,
        installmentsCount: installmentsCount,
        installmentValue: installmentValue,
        firstDueDate: firstDueDate,
        notes: notes,
      );

  Future<void> deleteProject(int projectId) =>
      _projects.deleteProject(projectId);

  Future<List<ProjectPayment>> loadProjectPayments({
    bool cacheFirst = true,
  }) =>
      _projectFinance.loadProjectPayments(cacheFirst: cacheFirst);

  Future<void> createProjectPayment({
    required int projectId,
    required double amount,
    required String paymentType,
    required DateTime paidAt,
    required String notes,
    required String idempotencyKey,
  }) =>
      _projectFinance.createProjectPayment(
        projectId: projectId,
        amount: amount,
        paymentType: paymentType,
        paidAt: paidAt,
        notes: notes,
        idempotencyKey: idempotencyKey,
      );

  Future<void> cancelProjectPayment(int paymentId) =>
      _projectFinance.cancelProjectPayment(paymentId);

  Future<void> createFollowUpMessage(Project project) =>
      _projects.createFollowUpMessage(project);

  Future<PvgisValidationResult> validateWithPvgis({
    required ProjectAddress address,
    required double installedPowerKwp,
    required double estimatedAnnualGeneration,
    double? latitude,
    double? longitude,
  }) =>
      _sizing.validateWithPvgis(
        address: address,
        installedPowerKwp: installedPowerKwp,
        estimatedAnnualGeneration: estimatedAnnualGeneration,
        latitude: latitude,
        longitude: longitude,
      );

  Future<PvgisValidationResult> lookupMonthlyHspWithPvgis({
    required ProjectAddress address,
  }) =>
      _sizing.lookupMonthlyHspWithPvgis(address: address);

  Future<void> createSizingProject({
    required int clientId,
    required String companyId,
    required ProjectAddress address,
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
  }) =>
      _sizing.createSizingProject(
        clientId: clientId,
        companyId: companyId,
        address: address,
        monthlyConsumption: monthlyConsumption,
        monthlyHsp: monthlyHsp,
        generationExtraPercent: generationExtraPercent,
        performanceRatio: performanceRatio,
        modulePower: modulePower,
        tariff: tariff,
        projectValue: projectValue,
        laborCost: laborCost,
        moduleUnitCost: moduleUnitCost,
        inverterCost: inverterCost,
        supportCost: supportCost,
        extraMaterials: extraMaterials,
        result: result,
      );

  Future<void> submitBetaFeedback({
    required String companyId,
    required int rating,
    required String area,
    required String message,
  }) =>
      _feedback.submitBetaFeedback(
        companyId: companyId,
        rating: rating,
        area: area,
        message: message,
      );

  Future<TeamInviteResult> inviteTeamUser({
    required String name,
    required String email,
    required String matricula,
    required String permission,
    required String role,
    String password = '',
  }) =>
      _team.inviteTeamUser(
        name: name,
        email: email,
        matricula: matricula,
        permission: permission,
        role: role,
        password: password,
      );

  Future<void> updateTeamUser({
    required String profileId,
    required String name,
    required String email,
    required String matricula,
    required String permission,
    required String role,
    required bool active,
    String password = '',
  }) =>
      _team.updateTeamUser(
        profileId: profileId,
        name: name,
        email: email,
        matricula: matricula,
        permission: permission,
        role: role,
        active: active,
        password: password,
      );

  Future<void> deleteTeamUser(String profileId) =>
      _team.deleteTeamUser(profileId);

  Future<List<BetaFeedback>> loadBetaFeedback() => _feedback.loadBetaFeedback();

  Future<void> updateBetaFeedbackStatus(int feedbackId, String status) =>
      _feedback.updateBetaFeedbackStatus(feedbackId, status);

  Future<List<AppMessage>> loadAppMessages({bool unreadOnly = false}) =>
      _messages.loadAppMessages(unreadOnly: unreadOnly);

  Future<void> markAppMessageRead(int messageId) =>
      _messages.markAppMessageRead(messageId);

  Future<void> archiveAppMessage(int messageId) =>
      _messages.archiveAppMessage(messageId);

  Future<List<ManualPayment>> loadManualPayments() =>
      _billing.loadManualPayments();

  Future<List<ManualPayment>> loadOpenManualPayments() =>
      _billing.loadOpenManualPayments();

  Future<void> createManualPayment({
    required double amount,
    required DateTime dueDate,
    required String pixReference,
    required String notes,
    required String idempotencyKey,
  }) =>
      _billing.createManualPayment(
        amount: amount,
        dueDate: dueDate,
        pixReference: pixReference,
        notes: notes,
        idempotencyKey: idempotencyKey,
      );

  Future<void> markManualPaymentPaid(int paymentId, {int periodMonths = 1}) =>
      _billing.markManualPaymentPaid(
        paymentId,
        periodMonths: periodMonths,
      );

  Future<void> cancelManualPayment(int paymentId) =>
      _billing.cancelManualPayment(paymentId);

  Future<void> syncOverdueManualPayments() =>
      _billing.syncOverdueManualPayments();

  Future<void> _refreshProjectsInBackground() =>
      _projects.refreshProjectsInBackground();

  Future<void> _refreshSubscriptionInBackground() =>
      _company.refreshSubscriptionInBackground();
}
