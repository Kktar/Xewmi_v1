import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? redirectTo;
  const LoginScreen({super.key, this.redirectTo});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  UserRole _selectedRole = UserRole.buyer;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _goNext() {
    final dest = widget.redirectTo;
    if (dest != null &&
        dest.isNotEmpty &&
        !dest.contains('login-callback') &&
        !dest.contains('io.supabase')) {
      context.go(dest);
    } else {
      context.go('/home');
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone invalide')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await ref.read(authControllerProvider.notifier).sendOtp(phone);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _otpSent = true;
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _isLoading = true);
    final ok = await ref.read(authControllerProvider.notifier).verifyOtp(
          _phoneController.text.trim(),
          _otpController.text.trim(),
        );
    if (ok) {
      await ref.read(authControllerProvider.notifier).setRole(_selectedRole);
      try {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          await Supabase.instance.client.from('profiles').update({
            'phone': '+221${_phoneController.text.trim()}',
            'whatsapp': '+221${_phoneController.text.trim()}',
          }).eq('id', uid);
        }
      } catch (_) {}
      if (mounted) _goNext();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code incorrect. Réessayez.')),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  /// Google natif (sans deep link navigateur)
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // Client ID Web (Supabase / Google Cloud)
      const webClientId =
          '32061553509-c89gs5eb2fin9j5m7hsk7peicifak84j.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize(
        serverClientId: webClientId,
      );

      if (!googleSignIn.supportsAuthenticate()) {
        throw Exception('Google Sign-In non supporté sur cette plateforme');
      }

      final account = await googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      // Récupérer les tokens pour Supabase
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw Exception('idToken manquant. Vérifiez serverClientId (Web).');
      }

      // accessToken : selon la version, via authorizationClient
      String? accessToken;
      try {
        final client = account.authorizationClient;
        final authz = await client.authorizationForScopes(['email', 'profile']);
        accessToken = authz?.accessToken;
      } catch (_) {
        // certaines versions exposent encore auth.accessToken
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      await ref.read(authControllerProvider.notifier).setRole(_selectedRole);

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'email': user.email,
          'google_email': user.email,
          'full_name': user.userMetadata?['full_name'] ?? account.displayName,
          'role': _selectedRole == UserRole.organizer ? 'organizer' : 'buyer',
        });
      }

      if (mounted) _goNext();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur Google: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _demoLogin() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInAnonymously();
      await ref.read(authControllerProvider.notifier).setRole(_selectedRole);
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': uid,
          'role': _selectedRole == UserRole.organizer ? 'organizer' : 'buyer',
          'full_name': _selectedRole == UserRole.organizer
              ? 'Organisateur Démo'
              : 'Client Démo',
          'phone': '+221770000000',
          'whatsapp': '+221770000000',
        });
      }
      if (mounted) _goNext();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Mode test: activez Anonymous dans Supabase.\n$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Bienvenue sur Sunu Tikeu',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _otpSent
                  ? 'Entrez le code reçu par SMS'
                  : 'Connectez-vous pour acheter ou organiser',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            if (!_otpSent) ...[
              const Text('Je suis',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      title: 'Client',
                      subtitle: 'Acheter des billets',
                      icon: Icons.confirmation_number_outlined,
                      selected: _selectedRole == UserRole.buyer,
                      onTap: () =>
                          setState(() => _selectedRole = UserRole.buyer),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleCard(
                      title: 'Organisateur',
                      subtitle: 'Créer des événements',
                      icon: Icons.storefront_outlined,
                      selected: _selectedRole == UserRole.organizer,
                      onTap: () =>
                          setState(() => _selectedRole = UserRole.organizer),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Numéro (WhatsApp / SMS)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixText: '+221  ',
                  hintText: '77 000 00 00',
                ),
              ),
            ] else ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  letterSpacing: 12,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '• • • • • •',
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(_otpSent ? 'Vérifier' : 'Recevoir le code'),
              ),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _otpSent = false),
                  child: const Text('Modifier le numéro'),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child:
                      Text('ou', style: TextStyle(color: AppColors.textMuted)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: const Text('Continuer avec Google'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isLoading ? null : _demoLogin,
                child: const Text('Mode test (sans SMS)'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 26),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                )),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
