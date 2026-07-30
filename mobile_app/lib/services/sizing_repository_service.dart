import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_subscription.dart';
import '../models/client.dart';
import 'pvgis_validation_service.dart';
import 'sizing_service.dart';

class SizingRepositoryService {
  SizingRepositoryService(
    this._supabase, {
    required this.currentCompanyId,
    required this.validateProjectCreation,
    required this.refreshProjectsInBackground,
  });

  final SupabaseClient _supabase;
  final Future<String> Function() currentCompanyId;
  final Future<SubscriptionValidation> Function({
    AppSubscription? cachedSubscription,
  }) validateProjectCreation;
  final Future<void> Function() refreshProjectsInBackground;

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
    final currentCompanyIdValue = await currentCompanyId();
    if (companyId != currentCompanyIdValue) {
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

    await refreshProjectsInBackground();
  }
}
