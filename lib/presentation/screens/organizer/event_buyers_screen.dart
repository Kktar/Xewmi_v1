import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/kyc_repository.dart';

/// Liste des acheteurs d'un événement + génération manuelle d'e-ticket
class EventBuyersScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventTitle;
  const EventBuyersScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  ConsumerState<EventBuyersScreen> createState() => _EventBuyersScreenState();
}

class _EventBuyersScreenState extends ConsumerState<EventBuyersScreen> {
  List<Map<String, dynamic>> _buyers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list =
        await ref.read(kycRepositoryProvider).getEventBuyers(widget.eventId);
    if (mounted) {
      setState(() {
        _buyers = list;
        _loading = false;
      });
    }
  }

  Future<void> _manualTicket() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Générer un e-ticket manuel',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nom du titulaire *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Téléphone / WhatsApp *',
                  prefixText: '+221 ',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.trim().length < 9 ? 'Invalide' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  child: const Text('Générer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true) return;

    try {
      // Délègue à la route generate existante avec extra
      await ref.read(kycRepositoryProvider).logActivity(
        action: 'manual_ticket_requested',
        eventId: widget.eventId,
        metadata: {
          'holder_name': nameCtrl.text.trim(),
          'holder_phone': phoneCtrl.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande enregistrée — ouvrez Générer un billet'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM · HH:mm', 'fr_FR');
    final money = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text(widget.eventTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _manualTicket,
        icon: const Icon(Icons.confirmation_number_outlined),
        label: const Text('E-ticket manuel'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buyers.isEmpty
              ? const Center(child: Text('Aucun acheteur pour cet événement'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: _buyers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final t = _buyers[i];
                    final order = t['orders'] as Map<String, dynamic>?;
                    final profile = order?['profiles'] as Map<String, dynamic>?;
                    final type = t['ticket_types'] as Map<String, dynamic>?;
                    final name =
                        t['holder_name'] ?? profile?['full_name'] ?? 'Acheteur';
                    final phone = t['holder_phone'] ??
                        profile?['whatsapp'] ??
                        profile?['phone'] ??
                        '—';
                    final email =
                        profile?['google_email'] ?? profile?['email'] ?? '—';
                    final status = t['status'] as String? ?? '';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(name.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: status == 'used'
                                      ? AppColors.textMuted
                                          .withValues(alpha: 0.15)
                                      : AppColors.successLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status == 'used' ? 'Utilisé' : 'Payé',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: status == 'used'
                                        ? AppColors.textSecondary
                                        : AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('📱 $phone',
                              style: const TextStyle(fontSize: 13)),
                          Text('✉️ $email',
                              style: const TextStyle(fontSize: 13)),
                          Text(
                            '🎫 ${type?['name'] ?? 'Billet'} · ${money.format(t['price'] ?? 0)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            '📅 ${t['created_at'] != null ? fmt.format(DateTime.parse(t['created_at'])) : '—'}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (order?['payment_method'] != null)
                            Text(
                              '💳 ${order!['payment_method']} · ${order['payment_reference'] ?? ''}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
