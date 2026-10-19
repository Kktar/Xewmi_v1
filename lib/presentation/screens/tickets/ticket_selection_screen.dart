import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/ticket_repository.dart';
import '../../providers/auth_provider.dart';
import '../event/event_detail_screen.dart';

class TicketSelectionScreen extends ConsumerStatefulWidget {
  final String eventId;
  const TicketSelectionScreen({super.key, required this.eventId});
  @override
  ConsumerState<TicketSelectionScreen> createState() =>
      _TicketSelectionScreenState();
}

class _TicketSelectionScreenState extends ConsumerState<TicketSelectionScreen> {
  final Map<String, int> _quantities = {};
  bool _loading = false;

  int get _total {
    final event = ref.read(eventDetailProvider(widget.eventId)).valueOrNull;
    if (event == null) return 0;
    int t = 0;
    for (final tt in event.ticketTypes) {
      t += (tt.price * (_quantities[tt.id] ?? 0));
    }
    return t;
  }

  int get _count => _quantities.values.fold(0, (a, b) => a + b);

  Future<void> _checkout() async {
    final event = ref.read(eventDetailProvider(widget.eventId)).valueOrNull;
    final user = ref.read(authStateProvider).valueOrNull;
    if (event == null || _count == 0) return;

    // Inscription / connexion uniquement au moment d'acheter
    if (user == null) {
      final redirect = Uri.encodeComponent('/event/${widget.eventId}/tickets');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connectez-vous pour acheter vos billets'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.push('/login?redirect=$redirect');
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final items = event.ticketTypes
          .where((t) => (_quantities[t.id] ?? 0) > 0)
          .map((t) => (
                ticketTypeId: t.id,
                name: t.name,
                price: t.price,
                qty: _quantities[t.id]!,
              ))
          .toList();

      final order = await ref.read(ticketRepositoryProvider).createOrder(
            userId: user.id,
            eventId: event.id,
            items: items,
          );
      if (mounted) context.push('/payment/${order.id}');
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
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Choix des billets')),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (event) {
          if (event == null) return const Center(child: Text('Introuvable'));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(event.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              ...event.ticketTypes.map((t) {
                final qty = _quantities[t.id] ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: qty > 0 ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              t.price == 0
                                  ? 'Gratuit'
                                  : '${NumberFormat('#,###', 'fr').format(t.price)} FCFA',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                            Text('${t.remaining} restants',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: qty > 0
                                ? () =>
                                    setState(() => _quantities[t.id] = qty - 1)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$qty',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          IconButton(
                            onPressed: qty < t.remaining
                                ? () =>
                                    setState(() => _quantities[t.id] = qty + 1)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ElevatedButton(
            onPressed: _count > 0 && !_loading ? _checkout : null,
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(
                    _count == 0
                        ? 'Sélectionnez des billets'
                        : 'Continuer · ${NumberFormat('#,###', 'fr').format(_total)} FCFA',
                  ),
          ),
        ),
      ),
    );
  }
}
