import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/beta_feedback.dart';

class FeedbackService {
  FeedbackService(
    this._supabase, {
    required this.currentCompanyId,
    required this.currentUserId,
    required this.ensureCompanyCanWrite,
  });

  final SupabaseClient _supabase;
  final Future<String> Function() currentCompanyId;
  final String? Function() currentUserId;
  final Future<void> Function(String action) ensureCompanyCanWrite;

  Future<void> submitBetaFeedback({
    required String companyId,
    required int rating,
    required String area,
    required String message,
  }) async {
    await ensureCompanyCanWrite('enviar feedback');
    await _supabase.from('beta_feedback').insert({
      'company_id': companyId,
      'profile_id': currentUserId(),
      'rating': rating,
      'area': area,
      'message': message.trim(),
      'app_version': 'Solar Pro Mobile 0.1.0',
    });
  }

  Future<List<BetaFeedback>> loadBetaFeedback() async {
    final companyId = await currentCompanyId();
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
    await ensureCompanyCanWrite('alterar feedbacks');
    await _supabase.from('beta_feedback').update({
      'status': status,
      'resolved_at':
          status == 'resolved' ? DateTime.now().toIso8601String() : null,
    }).eq('id', feedbackId);
  }
}
