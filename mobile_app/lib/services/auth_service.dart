import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_profile.dart';
import 'cache_service.dart';

class AuthService {
  AuthService(this._supabase, this._cache, this._cacheScopePrefix);

  final SupabaseClient _supabase;
  final CacheService _cache;
  final String Function() _cacheScopePrefix;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authChanges => _supabase.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> sendPasswordRecoveryCode(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> resetPasswordWithRecoveryCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _supabase.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.recovery,
    );
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    await signOut();
  }

  Future<void> signOut() async {
    final prefix = _cacheScopePrefix();
    await _supabase.auth.signOut();
    await _cache.removeByPrefix(prefix);
  }

  Future<AppProfile> loadProfile() async {
    final userId = currentUser?.id;
    if (userId == null) throw StateError('Usuário não autenticado.');
    final row =
        await _supabase.from('profiles').select().eq('id', userId).single();
    return AppProfile.fromMap(row);
  }
}
