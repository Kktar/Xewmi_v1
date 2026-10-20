import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges.map((event) => event.session?.user);
});

final currentProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;
  final repo = ref.watch(authRepositoryProvider);
  return repo.getProfile(user.id);
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AuthController(this._ref) : super(const AsyncValue.data(null));

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  Future<void> sendOtp(String phone) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.signInWithPhone(phone));
  }

  Future<bool> verifyOtp(String phone, String token) async {
    state = const AsyncValue.loading();
    try {
      await _repo.verifyOtp(phone: phone, token: token);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> setRole(UserRole role) async {
    await _repo.updateProfile(
      role: role == UserRole.organizer ? 'organizer' : 'buyer',
    );
    _ref.invalidate(currentProfileProvider);
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }
}
