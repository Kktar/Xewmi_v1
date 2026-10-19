import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/event_repository.dart';
import '../event/event_detail_screen.dart';

class EventPreviewScreen extends ConsumerWidget {
  final String eventId;
  const EventPreviewScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Aperçu avant publication')),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (event) {
          if (event == null) return const SizedBox();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.warningDark),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vérifiez les informations avant de publier. Une fois publié, l\'événement sera visible par tous.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.warningDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(event.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('${event.venue}, ${event.city}',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(event.startAt.toString().substring(0, 16),
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Text(event.description ?? '',
                  style: const TextStyle(height: 1.5)),
              const SizedBox(height: 20),
              const Text('Billets',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ...event.ticketTypes.map((t) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.name),
                    trailing: Text('${t.price} FCFA × ${t.quantity}'),
                  )),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(eventRepositoryProvider)
                      .publishEvent(eventId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Événement publié !'),
                          backgroundColor: AppColors.success),
                    );
                    context.go('/organizer');
                  }
                },
                child: const Text('Publier l\'événement'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/organizer'),
                child: const Text('Enregistrer en brouillon'),
              ),
            ],
          );
        },
      ),
    );
  }
}
