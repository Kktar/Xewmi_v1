import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _editingName = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(fullName: name);
      ref.invalidate(currentProfileProvider);
      setState(() => _editingName = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _switchRole(UserRole newRole) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              newRole == UserRole.organizer
                  ? Icons.storefront_rounded
                  : Icons.confirmation_number_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              newRole == UserRole.organizer
                  ? 'Passer en mode Organisateur ?'
                  : 'Passer en mode Acheteur ?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              newRole == UserRole.organizer
                  ? 'Vous pourrez créer des événements, scanner et générer des billets.'
                  : 'Vous pourrez parcourir et acheter des billets pour des événements.',
              style:
                  const TextStyle(color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Confirmer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(authControllerProvider.notifier).setRole(newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newRole == UserRole.organizer
                  ? 'Mode Organisateur activé'
                  : 'Mode Acheteur activé',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        if (newRole == UserRole.organizer) {
          context.go('/organizer');
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Se déconnecter'),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter de Sunu Tikeu ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_outlined,
                      size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text('Non connecté'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            );
          }

          final isOrganizer = profile.role == UserRole.organizer;
          final initial =
              (profile.displayName.isNotEmpty ? profile.displayName[0] : '?')
                  .toUpperCase();

          return CustomScrollView(
            slivers: [
              // Header avec gradient
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => context.pop(),
                                icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 20),
                              ),
                              const Expanded(
                                child: Text(
                                  'Mon profil',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Avatar
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: profile.avatarUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      profile.avatarUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            profile.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOrganizer
                                      ? Icons.storefront_rounded
                                      : Icons.confirmation_number_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOrganizer ? 'Organisateur' : 'Acheteur',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Contenu
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -16),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Infos personnelles
                          const _SectionTitle(
                            icon: Icons.person_outline_rounded,
                            title: 'Informations',
                          ),
                          const SizedBox(height: 12),
                          _InfoCard(
                            children: [
                              // Nom
                              if (_editingName) ...[
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _nameController,
                                          autofocus: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Nom complet',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: _saving ? null : _saveName,
                                        icon: _saving
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              )
                                            : const Icon(Icons.check_circle,
                                                color: AppColors.success),
                                      ),
                                      IconButton(
                                        onPressed: () => setState(
                                            () => _editingName = false),
                                        icon: const Icon(Icons.close,
                                            color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else
                                _ProfileTile(
                                  icon: Icons.badge_outlined,
                                  iconColor: AppColors.primary,
                                  title: 'Nom',
                                  subtitle: profile.displayName,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 20),
                                    onPressed: () {
                                      _nameController.text =
                                          profile.fullName ?? '';
                                      setState(() => _editingName = true);
                                    },
                                  ),
                                ),
                              const Divider(height: 1, indent: 60),
                              _ProfileTile(
                                icon: Icons.phone_outlined,
                                iconColor: AppColors.success,
                                title: 'Téléphone',
                                subtitle: profile.phone ?? 'Non renseigné',
                              ),
                              const Divider(height: 1, indent: 60),
                              _ProfileTile(
                                icon: Icons.email_outlined,
                                iconColor: AppColors.secondary,
                                title: 'E-mail',
                                subtitle: profile.email ?? 'Non renseigné',
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Mode / Rôle
                          const _SectionTitle(
                            icon: Icons.swap_horiz_rounded,
                            title: 'Mode de compte',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _RoleCard(
                                  icon: Icons.confirmation_number_rounded,
                                  title: 'Acheteur',
                                  subtitle: 'Acheter des billets',
                                  selected: !isOrganizer,
                                  color: AppColors.primary,
                                  onTap: isOrganizer
                                      ? () => _switchRole(UserRole.buyer)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RoleCard(
                                  icon: Icons.storefront_rounded,
                                  title: 'Organisateur',
                                  subtitle: 'Vendre & gérer',
                                  selected: isOrganizer,
                                  color: AppColors.secondary,
                                  onTap: !isOrganizer
                                      ? () => _switchRole(UserRole.organizer)
                                      : null,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Actions rapides
                          const _SectionTitle(
                            icon: Icons.bolt_rounded,
                            title: 'Actions',
                          ),
                          const SizedBox(height: 12),
                          _InfoCard(
                            children: [
                              if (isOrganizer)
                                _ProfileTile(
                                  icon: Icons.dashboard_customize_rounded,
                                  iconColor: AppColors.secondary,
                                  title: 'Tableau de bord',
                                  subtitle: 'Gérer mes événements',
                                  trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textMuted),
                                  onTap: () => context.push('/organizer'),
                                ),
                              if (isOrganizer)
                                const Divider(height: 1, indent: 60),
                              if (isOrganizer)
                                _ProfileTile(
                                  icon: Icons.qr_code_scanner_rounded,
                                  iconColor: AppColors.success,
                                  title: 'Scanner un billet',
                                  subtitle: 'Contrôle d\'accès',
                                  trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textMuted),
                                  onTap: () => context.push('/organizer/scan'),
                                ),
                              if (isOrganizer)
                                const Divider(height: 1, indent: 60),
                              _ProfileTile(
                                icon: Icons.confirmation_number_outlined,
                                iconColor: AppColors.warning,
                                title: 'Mes billets',
                                subtitle: 'Billets achetés',
                                trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textMuted),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Liste des billets — bientôt'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Déconnexion
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _logout,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text(
                                'Se déconnecter',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Sunu Tikeu v1.0.0',
                              style: TextStyle(
                                color:
                                    AppColors.textMuted.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Widgets privés ───────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: trailing,
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? color : AppColors.textMuted, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? color : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (selected) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    'Actif',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ] else if (onTap != null) ...[
              const SizedBox(height: 8),
              Text(
                'Changer →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
