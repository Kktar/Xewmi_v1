import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/event_repository.dart';
import '../../providers/auth_provider.dart';

final organizerEventsProvider =
    FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];
  return ref.watch(eventRepositoryProvider).getOrganizerEvents(user.id);
});

class OrganizerDashboardScreen extends ConsumerWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(organizerEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Tableau de bord',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scanner',
            onPressed: () => context.push('/organizer/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profil',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (events) {
          final totalSold = events.fold<int>(0, (s, e) => s + e.ticketsSold);
          final totalCapacity =
              events.fold<int>(0, (s, e) => s + e.totalTickets);
          final totalRevenue = events.fold<int>(0, (s, e) {
            return s +
                e.ticketTypes.fold<int>(0, (ss, t) => ss + (t.sold * t.price));
          });
          final published =
              events.where((e) => e.status == EventStatus.published).length;

          // Agrégation ventes par type de billet (tous événements)
          final Map<String, _TypeAgg> byType = {};
          for (final e in events) {
            for (final t in e.ticketTypes) {
              final key = t.name;
              final prev = byType[key];
              byType[key] = _TypeAgg(
                name: t.name,
                sold: (prev?.sold ?? 0) + t.sold,
                quantity: (prev?.quantity ?? 0) + t.quantity,
                revenue: (prev?.revenue ?? 0) + (t.sold * t.price),
              );
            }
          }
          final typeList = byType.values.toList()
            ..sort((a, b) => b.revenue.compareTo(a.revenue));

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(organizerEventsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                // ── Stats globales ──────────────────────────
                Row(
                  children: [
                    _StatCard(
                      icon: Icons.event_rounded,
                      label: 'Événements',
                      value: '${events.length}',
                      sub: '$published publiés',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: Icons.confirmation_number_rounded,
                      label: 'Billets vendus',
                      value: '$totalSold',
                      sub: 'sur $totalCapacity',
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _RevenueCard(amount: totalRevenue),

                // ── Ventes par type de billet ───────────────
                const SizedBox(height: 28),
                const Text(
                  'Ventes par type de billet',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Détail consolidé sur tous vos événements',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                if (typeList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Center(
                      child: Text(
                        'Aucune vente pour le moment',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...typeList.map((t) => _TicketTypeSalesCard(agg: t)),

                // ── Actions rapides ─────────────────────────
                const SizedBox(height: 28),
                const Text(
                  'Actions rapides',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Créer',
                        color: AppColors.primary,
                        onTap: () => context.push('/organizer/create-event'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Scanner',
                        color: AppColors.success,
                        onTap: () => context.push('/organizer/scan'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.confirmation_number_outlined,
                        label: 'Scan',
                        color: AppColors.secondary,
                        onTap: () => context.push('/organizer/scan'),
                      ),
                    ),
                  ],
                ),

                // ── Liste événements avec détail types ──────
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mes événements',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/organizer/create-event'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Créer'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (events.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.event_busy_rounded,
                            size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'Aucun événement.\nCréez votre premier événement !',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  ...events.map((e) => _EventDetailCard(event: e)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/organizer/create-event'),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel événement'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ─── Data helper ──────────────────────────────────────────────

class _TypeAgg {
  final String name;
  final int sold;
  final int quantity;
  final int revenue;
  const _TypeAgg({
    required this.name,
    required this.sold,
    required this.quantity,
    required this.revenue,
  });
  double get fill => quantity == 0 ? 0 : sold / quantity;
}

// ─── Widgets ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value, sub;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(sub,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final int amount;
  const _RevenueCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9A3412), Color(0xFFB45309)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payments_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Revenus totaux (billets vendus)',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fmt.format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketTypeSalesCard extends StatelessWidget {
  final _TypeAgg agg;
  const _TicketTypeSalesCard({required this.agg});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
    final pct = (agg.fill * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  agg.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                fmt.format(agg.revenue),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${agg.sold} vendus',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                ' / ${agg.quantity} dispo',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '$pct %',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: agg.fill.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDetailCard extends StatelessWidget {
  final EventModel event;
  const _EventDetailCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
    final dateFmt = DateFormat('d MMM yyyy · HH:mm', 'fr_FR');
    final revenue =
        event.ticketTypes.fold<int>(0, (s, t) => s + (t.sold * t.price));
    final statusColor = switch (event.status) {
      EventStatus.published => AppColors.success,
      EventStatus.draft => AppColors.warning,
      EventStatus.cancelled => AppColors.error,
      EventStatus.completed => AppColors.textSecondary,
    };
    final statusLabel = switch (event.status) {
      EventStatus.published => 'Publié',
      EventStatus.draft => 'Brouillon',
      EventStatus.cancelled => 'Annulé',
      EventStatus.completed => 'Terminé',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header événement
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.venue} · ${event.city}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFmt.format(event.startAt),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Résumé ventes événement
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _MiniStat(
                  label: 'Vendus',
                  value: '${event.ticketsSold}/${event.totalTickets}',
                ),
                const SizedBox(width: 16),
                _MiniStat(
                  label: 'Revenu',
                  value: fmt.format(revenue),
                ),
              ],
            ),
          ),

          // Détail par type de billet
          if (event.ticketTypes.isNotEmpty) ...[
            const Divider(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: Text(
                'Détail par type',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ),
            ...event.ticketTypes.map((t) {
              final fill = t.quantity == 0 ? 0.0 : t.sold / t.quantity;
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        Text(
                          '${t.sold}/${t.quantity}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          fmt.format(t.sold * t.price),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: fill.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: AppColors.borderLight,
                        color: AppColors.primary,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Prix unitaire : ${fmt.format(t.price)} · Restant : ${t.remaining}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () =>
                      context.push('/organizer/preview/${event.id}'),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Aperçu'),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/organizer/scan'),
                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                  label: const Text('Scanner'),
                ),
                const Spacer(),
                if (event.status == EventStatus.draft)
                  TextButton(
                    onPressed: () {
                      // publish via repository could be wired here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Publication — utilisez Aperçu')),
                      );
                    },
                    child: const Text('Publier'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      ],
    );
  }
}
