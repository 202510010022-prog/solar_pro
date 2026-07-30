import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_subscription.dart';
import '../models/project.dart';
import 'cache_service.dart';

class CompanyService {
  CompanyService(
    this._supabase,
    this._cache, {
    required this.currentCompanyId,
    required this.cacheKey,
    required this.loadProjects,
  });

  final SupabaseClient _supabase;
  final CacheService _cache;
  final Future<String> Function() currentCompanyId;
  final String Function(String key) cacheKey;
  final Future<List<Project>> Function({bool cacheFirst}) loadProjects;

  Future<AppSubscription> loadSubscription({bool cacheFirst = true}) async {
    final key = cacheKey('subscription');
    if (cacheFirst) {
      final cached = await _cache.loadJsonList(key);
      if (cached.isNotEmpty) {
        refreshSubscriptionInBackground();
        return AppSubscription.fromMap(cached.first);
      }
    }

    final row = await _supabase
        .from('company_billing_overview')
        .select()
        .eq('company_id', await currentCompanyId())
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

  Future<void> refreshSubscriptionInBackground() async {
    try {
      final row = await _supabase
          .from('company_billing_overview')
          .select()
          .eq('company_id', await currentCompanyId())
          .limit(1)
          .single();
      await _cache.saveJsonList(
        cacheKey('subscription'),
        [Map<String, dynamic>.from(row)],
      );
    } catch (_) {
      // Offline-first: cache remains valid when network is unavailable.
    }
  }
}
