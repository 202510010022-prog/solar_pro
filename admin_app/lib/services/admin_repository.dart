import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_data.dart';

class AdminRepository {
  AdminRepository(this.client);

  final SupabaseClient client;

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => client.auth.signOut();

  Future<AdminData> loadData() async {
    final results = await Future.wait([
      _invoke('list_companies'),
      _invoke('list_plans'),
      _invoke('list_payments'),
      _invoke('list_feedbacks'),
      _invoke('list_messages'),
      _invoke('list_users'),
    ]);
    return AdminData.fromMaps(
      results[0],
      results[1],
      results[2],
      results[3],
      results[4],
      results[5],
    );
  }

  Future<void> createCompany({
    required String companyName,
    required String document,
    required String planSlug,
    required String status,
    required String billingEmail,
    required int trialDays,
    required String masterName,
    required String masterEmail,
    required String matricula,
    required String password,
  }) async {
    await _invoke(
      'create_company',
      body: {
        'company': {
          'name': companyName,
          'document': document,
          'plan_slug': planSlug,
          'subscription_status': status,
          'billing_email': billingEmail,
          'trial_days': trialDays,
        },
        'master': {
          'name': masterName,
          'email': masterEmail,
          'matricula': matricula,
          'password': password,
        },
      },
    );
  }

  Future<void> updateCompany({
    required String companyId,
    required String name,
    required String document,
    required String planSlug,
    required String status,
    required String billingEmail,
    required bool active,
    String subscriptionEndsAt = '',
  }) async {
    await _invoke(
      'update_company',
      body: {
        'company': {
          'id': companyId,
          'name': name,
          'document': document,
          'plan_slug': planSlug,
          'subscription_status': status,
          'billing_email': billingEmail,
          'active': active,
          'subscription_ends_at': subscriptionEndsAt,
        },
      },
    );
  }

  Future<void> createPayment({
    required String companyId,
    required double amount,
    required DateTime dueDate,
    required String pixReference,
    required String notes,
    required String idempotencyKey,
  }) async {
    await _invoke(
      'create_payment',
      body: {
        'payment': {
          'company_id': companyId,
          'amount': amount,
          'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
          'pix_reference': pixReference,
          'notes': notes,
          'idempotency_key': idempotencyKey,
        },
      },
    );
  }

  Future<void> markPaymentPaid(int paymentId, {int periodMonths = 1}) async {
    await _invoke(
      'mark_payment_paid',
      body: {
        'payment': {'id': paymentId, 'period_months': periodMonths},
      },
    );
  }

  Future<void> cancelPayment(int paymentId) async {
    await _invoke(
      'cancel_payment',
      body: {
        'payment': {'id': paymentId},
      },
    );
  }

  Future<void> updateFeedback(int feedbackId, String status) async {
    await _invoke(
      'update_feedback',
      body: {
        'feedback': {'id': feedbackId, 'status': status},
      },
    );
  }

  Future<void> createMessage({
    required String companyId,
    required bool sendToAll,
    required String title,
    required String message,
    required String type,
    String expiresAt = '',
  }) async {
    await _invoke(
      'create_message',
      body: {
        'message': {
          'company_id': companyId,
          'send_to_all': sendToAll,
          'title': title,
          'message': message,
          'type': type,
          'expires_at': expiresAt,
        },
      },
    );
  }

  Future<void> createUser({
    required String companyId,
    required String name,
    required String email,
    required String matricula,
    required String role,
    required String permission,
    required String password,
  }) async {
    await _invoke(
      'create_user',
      body: {
        'user': {
          'company_id': companyId,
          'name': name,
          'email': email,
          'matricula': matricula,
          'role': role,
          'permission': permission,
          'password': password,
        },
      },
    );
  }

  Future<void> updateUser({
    required String userId,
    required String companyId,
    required String name,
    required String email,
    required String matricula,
    required String role,
    required String permission,
    required bool active,
    String password = '',
  }) async {
    await _invoke(
      'update_user',
      body: {
        'user': {
          'id': userId,
          'company_id': companyId,
          'name': name,
          'email': email,
          'matricula': matricula,
          'role': role,
          'permission': permission,
          'active': active,
          'password': password,
        },
      },
    );
  }

  Future<void> updateUserActive(String userId, bool active) async {
    await _invoke(
      'update_user_active',
      body: {
        'user': {'id': userId, 'active': active},
      },
    );
  }

  Future<Map<String, dynamic>> _invoke(
    String action, {
    Map<String, dynamic> body = const {},
  }) async {
    try {
      final response = await client.functions.invoke(
        'admin-company',
        body: {'action': action, ...body},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['error'] != null) throw StateError('${data['error']}');
        return data;
      }
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        if (map['error'] != null) throw StateError('${map['error']}');
        return map;
      }
      throw StateError('Resposta administrativa invalida.');
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        throw StateError('${details['error']}');
      }
      throw StateError(error.reasonPhrase ?? 'Operacao administrativa falhou.');
    }
  }
}
