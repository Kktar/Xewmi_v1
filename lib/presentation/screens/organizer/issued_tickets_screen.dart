import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/repositories/ticket_repository.dart';

final issuedTicketsProvider = FutureProvider.autoDispose
    .family<List<TicketModel>, String>((ref, eventId) {
  return ref.watch(ticketRepositoryProvider).getEventTickets(eventId);
});

class IssuedTicketsScreen extends ConsumerWidget {
  final String eventId;
  const IssuedTicketsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(issuedTicketsProvider(eventId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Billets émis')),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (tickets) {
          if (tickets.isEmpty) {
            return const Center(child: Text('Aucun billet émis'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = tickets[i];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                tileColor: AppColors.surface,
                leading: Icon(
                  t.isUsed ? Icons.check_circle : Icons.confirmation_number,
                  color: t.isUsed ? AppColors.success : AppColors.primary,
                ),
                title: Text(t.ticketTypeName ?? 'Billet',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  t.holderName ??
                      DateFormat('dd/MM/yyyy HH:mm').format(t.createdAt),
                ),
                trailing: Text(
                  t.isUsed ? 'Utilisé' : 'Valide',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.isUsed ? AppColors.textMuted : AppColors.success,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
