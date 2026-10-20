import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/ticket_model.dart';
import '../../../services/supabase_service.dart';

final ticketByIdProvider = FutureProvider.autoDispose
    .family<TicketModel?, String>((ref, ticketId) async {
  final client = SupabaseService.client;
  final data = await client.from('tickets').select('''
        *,
        events(title, venue, city, start_at),
        ticket_types(name)
      ''').eq('id', ticketId).maybeSingle();
  if (data == null) return null;
  final map = Map<String, dynamic>.from(data);
  map['event_title'] = map['events']?['title'];
  map['event_venue'] = map['events']?['venue'];
  map['event_start_at'] = map['events']?['start_at'];
  map['ticket_type_name'] = map['ticket_types']?['name'];
  return TicketModel.fromJson(map);
});

class ETicketScreen extends ConsumerWidget {
  final String ticketId;
  const ETicketScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketByIdProvider(ticketId));
    final dateFmt = DateFormat('EEE d MMM yyyy · HH:mm', 'fr_FR');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Billet électronique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              final t = ticketAsync.valueOrNull;
              final title = t?.eventTitle ?? 'Événement';
              Share.share(
                'Mon billet Sunu Tikeu pour $title\nCode: ${t?.qrCode ?? ticketId}',
              );
            },
          ),
        ],
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (ticket) {
          if (ticket == null) {
            return const Center(child: Text('Billet introuvable'));
          }
          final isUsed = ticket.status == TicketStatus.used;
          final startAt = ticket.eventStartAt;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sunu Tikeu',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ticket.eventTitle ?? 'Événement',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (ticket.eventVenue != null) ticket.eventVenue!,
                        if (startAt != null) dateFmt.format(startAt),
                      ].join(' · '),
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ticket.ticketTypeName ?? 'Billet',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Opacity(
                      opacity: isUsed ? 0.4 : 1,
                      child: QrImageView(
                        data: ticket.qrCode,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isUsed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Billet déjà utilisé',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Valide',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SelectableText(
                      ticket.qrCode,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (ticket.holderName != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Titulaire : ${ticket.holderName}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
