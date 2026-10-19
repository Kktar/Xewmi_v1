import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  final _client = SupabaseService.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<UserModel?> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  /// Connexion / inscription par téléphone (OTP SMS via Supabase)
  Future<void> signInWithPhone(String phone) async {
    // Format Sénégal : +221XXXXXXXXX
    final formatted = phone.startsWith('+') ? phone : '+221$phone';
    await _client.auth.signInWithOtp(phone: formatted);
  }

  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    final formatted = phone.startsWith('+') ? phone : '+221$phone';
    return _client.auth.verifyOTP(
      phone: formatted,
      token: token,
      type: OtpType.sms,
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<void> updateProfile({
    String? fullName,
    String? role,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (role != null) updates['role'] = role;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (updates.isEmpty) return;

    await _client
        .from('profiles')
        .update(updates)
        .eq('id', currentUser!.id);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
