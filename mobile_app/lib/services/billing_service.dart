import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/manual_payment.dart';

class BillingService {
  BillingService(
    this._supabase, {
    required this.currentCompanyId,
    required this.ensureCompanyCanWrite,
    required this.refreshSubscriptionInBackground,
  });

  final SupabaseClient _supabase;
  final Future<String> Function() currentCompanyId;
  final Future<void> Function(String action) ensureCompanyCanWrite;
  final Future<void> Function() refreshSubscriptionInBackground;

  Future<List<ManualPayment>> loadManualPayments() async {
    final companyId = await currentCompanyId();
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
    final companyId = await currentCompanyId();
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
    await ensureCompanyCanWrite('criar cobranças');
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
    await ensureCompanyCanWrite('confirmar cobranças');
    await _invokePaymentAction({
      'action': 'mark_paid',
      'payment_id': paymentId,
      'period_months': periodMonths,
    });
    await refreshSubscriptionInBackground();
  }

  Future<void> cancelManualPayment(int paymentId) async {
    await ensureCompanyCanWrite('cancelar cobranças');
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
}
