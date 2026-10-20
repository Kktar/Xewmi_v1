import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/event_repository.dart';

final eventDetailProvider =
    FutureProvider.autoDispose.family<EventModel?, String>((ref, id) {
  return ref.watch(eventRepositoryProvider).getEventById(id);
});

class EventDetailScreen extends ConsumerWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final dateFormat = DateFormat('EEEE d MMMM yyyy · HH:mm', 'fr_FR');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorUi.errorView(
          error: e,
          onRetry: () => ref.invalidate(eventDetailProvider(eventId)),
          title: 'Impossible de charger l\'événement',
        ),
        data: (event) {
          if (event == null) {
            return ErrorUi.emptyView(
              title: 'Événement introuvable',
              subtitle: 'Cet événement n\'existe pas ou a été retiré.',
              icon: Icons.event_busy_rounded,
              actionLabel: 'Retour à l\'accueil',
              onAction: () => context.go('/home'),
            );
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppColors.background,
                flexibleSpace: FlexibleSpaceBar(
                  background: event.coverImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: event.coverImageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(color: AppColors.primaryLight),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.category,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryDark,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        text: dateFormat.format(event.startAt),
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: '${event.venue}, ${event.city}',
                      ),
                      if (event.organizerName != null) ...[
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.person_outline,
                          text: 'Organisé par ${event.organizerName}',
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'À propos',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description ?? 'Aucune description disponible.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Types de billets',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      ...event.ticketTypes.map((t) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(t.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      if (t.description != null)
                                        Text(t.description!,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color:
                                                    AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Text(
                                  t.price == 0
                                      ? 'Gratuit'
                                      : '${NumberFormat('#,###', 'fr').format(t.price)} F',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: eventAsync.whenOrNull(
        data: (event) {
          if (event == null || event.isSoldOut) return null;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: ElevatedButton(
                onPressed: () => context.push('/event/${event.id}/tickets'),
                child: Text(
                  'Choisir mes billets · Dès ${NumberFormat('#,###', 'fr').format(event.minPrice)} FCFA',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
