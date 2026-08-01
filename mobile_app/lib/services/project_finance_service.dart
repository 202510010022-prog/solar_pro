import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/project_payment.dart';

class ProjectFinanceService {
  ProjectFinanceService(
    this._supabase, {
    required this.currentCompanyId,
    required this.currentUserId,
    required this.ensureCompanyCanWrite,
    required this.refreshProjectsInBackground,
  });

  final SupabaseClient _supabase;
  final Future<String> Function() currentCompanyId;
  final String? Function() currentUserId;
  final Future<void> Function(String action) ensureCompanyCanWrite;
  final Future<void> Function() refreshProjectsInBackground;

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
    await ensureCompanyCanWrite('editar financeiro do projeto');
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
    await refreshProjectsInBackground();
  }

  Future<List<ProjectPayment>> loadProjectPayments({
    bool cacheFirst = true,
  }) async {
    final companyId = await currentCompanyId();
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
    required String idempotencyKey,
  }) async {
    await ensureCompanyCanWrite('registrar pagamentos de clientes');
    final companyId = await currentCompanyId();
    await _supabase.from('project_payments').insert({
      'company_id': companyId,
      'project_id': projectId,
      'amount': amount,
      'payment_type': paymentType.trim(),
      'paid_at': paidAt.toIso8601String(),
      'status': 'paid',
      'notes': notes.trim(),
      'created_by': currentUserId(),
      'idempotency_key': idempotencyKey,
    });
  }

  Future<void> cancelProjectPayment(int paymentId) async {
    await ensureCompanyCanWrite('cancelar pagamentos de clientes');
    final companyId = await currentCompanyId();
    await _supabase
        .from('project_payments')
        .update({
          'status': 'canceled',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', paymentId)
        .eq('company_id', companyId);
  }
}
