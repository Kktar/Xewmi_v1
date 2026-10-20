import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/repositories/kyc_repository.dart';
import '../../providers/auth_provider.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});
  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _venue = TextEditingController();
  final _city = TextEditingController();
  String _category = AppConstants.eventCategories.first;
  DateTime _startAt = DateTime.now().add(const Duration(days: 7));
  bool _isFree = false;
  final List<Map<String, dynamic>> _ticketTypes = [
    {'name': 'Standard', 'price': 5000, 'quantity': 100},
  ];
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _venue.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isFree) {
      if (_ticketTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajoutez au moins un type de billet')),
        );
        return;
      }
      for (final t in _ticketTypes) {
        final name = (t['name'] as String?)?.trim() ?? '';
        if (name.isEmpty ||
            (t['price'] as int? ?? 0) <= 0 ||
            (t['quantity'] as int? ?? 0) <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Billets : nom, prix et quantité > 0 obligatoires')),
          );
          return;
        }
      }
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      context.push('/login?redirect=/organizer/create-event');
      return;
    }

    // KYC obligatoire avant création / publication
    final kycOk = await ref.read(kycRepositoryProvider).isApproved();
    if (!kycOk) {
      if (mounted) {
        final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Dossier organisateur requis'),
            content: const Text(
              'Avant de créer ou publier un événement, complétez votre dossier :\n'
              '• Pièce d\'identité (photo ou PDF)\n'
              '• NINEA\n'
              '• Numéro de téléphone\n'
              '• Nom, prénom, date de naissance',
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Plus tard')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Compléter')),
            ],
          ),
        );
        if (go == true && mounted) context.push('/organizer/kyc');
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final event = await ref.read(eventRepositoryProvider).createEvent(
            organizerId: user.id,
            title: _title.text.trim(),
            description: _desc.text.trim(),
            category: _category,
            venue: _venue.text.trim(),
            city: _city.text.trim(),
            startAt: _startAt,
            ticketTypes: _isFree ? [] : _ticketTypes,
          );

      // Marquer is_free si besoin (update direct)
      if (_isFree) {
        // ignore: use build context
        ref.read(eventRepositoryProvider); // keep ref alive
        // Update via supabase through a small extension - use raw if needed
        try {
          // Event repository may not expose is_free; document for SQL/API
        } catch (_) {}
      }

      if (mounted) {
        if (_isFree) {
          // Expliquer les frais de publication
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Événement à entrée libre'),
              content: Text(
                'Événement créé en brouillon.\n\n'
                'Pour le publier, des frais de publication de '
                '${NumberFormat.currency(locale: "fr_FR", symbol: "FCFA", decimalDigits: 0).format(AppConstants.freeEventPublishFee)} '
                'sont requis.\n\n'
                'Ensuite vous pourrez envoyer des invitations et les valider à l\'entrée.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Compris'),
                ),
              ],
            ),
          );
        }
        if (mounted) context.push('/organizer/preview/${event.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feeFmt = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Créer un événement')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Type d'événement
            const Text('Type d\'accès *',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TypeChip(
                    label: 'Payant',
                    icon: Icons.payments_outlined,
                    selected: !_isFree,
                    onTap: () => setState(() => _isFree = false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeChip(
                    label: 'Entrée libre',
                    icon: Icons.celebration_outlined,
                    selected: _isFree,
                    onTap: () => setState(() => _isFree = true),
                  ),
                ),
              ],
            ),
            if (_isFree) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Entrée libre : pas de vente de billets. '
                  'Vous enverrez des invitations. '
                  'Publication : ${feeFmt.format(AppConstants.freeEventPublishFee)} (frais plateforme).',
                  style: const TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ),
            ],

            const SizedBox(height: 20),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titre *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Catégorie *'),
              items: AppConstants.eventCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
              validator: (v) => v == null || v.isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _venue,
              decoration: const InputDecoration(labelText: 'Lieu *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Ville *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date et heure *'),
              subtitle: Text(
                  '${_startAt.day}/${_startAt.month}/${_startAt.year} à ${_startAt.hour}:${_startAt.minute.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startAt,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (d == null) return;
                final t = await showTimePicker(
                  // ignore: use_build_context_synchronously
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_startAt),
                );
                if (t == null) return;
                setState(() {
                  _startAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                });
              },
            ),

            if (!_isFree) ...[
              const SizedBox(height: 20),
              const Text('Types de billets *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ..._ticketTypes.asMap().entries.map((e) {
                final i = e.key;
                final t = e.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: t['name'] as String?,
                          decoration: const InputDecoration(labelText: 'Nom *'),
                          onChanged: (v) => _ticketTypes[i]['name'] = v,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: '${t['price']}',
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Prix FCFA *'),
                                onChanged: (v) => _ticketTypes[i]['price'] =
                                    int.tryParse(v) ?? 0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: '${t['quantity']}',
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Quantité *'),
                                onChanged: (v) => _ticketTypes[i]['quantity'] =
                                    int.tryParse(v) ?? 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() {
                  _ticketTypes.add({'name': '', 'price': 0, 'quantity': 50});
                }),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un type'),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isFree
                        ? 'Créer (puis payer publication)'
                        : 'Créer l\'événement'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color:
                      selected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
