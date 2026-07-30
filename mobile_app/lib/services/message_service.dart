import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_message.dart';

class MessageService {
  MessageService(
    this._supabase, {
    required this.currentCompanyId,
    required this.ensureCompanyCanWrite,
  });

  final SupabaseClient _supabase;
  final Future<String> Function() currentCompanyId;
  final Future<void> Function(String action) ensureCompanyCanWrite;

  Future<List<AppMessage>> loadAppMessages({bool unreadOnly = false}) async {
    final companyId = await currentCompanyId();
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
    await ensureCompanyCanWrite('alterar mensagens');
    await _supabase.from('app_messages').update({
      'status': 'read',
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  Future<void> archiveAppMessage(int messageId) async {
    await ensureCompanyCanWrite('arquivar mensagens');
    await _supabase.from('app_messages').update({
      'status': 'archived',
    }).eq('id', messageId);
  }
}
