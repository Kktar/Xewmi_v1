import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';

class TicketReadyScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const TicketReadyScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final tickets = (data['tickets'] as List?)?.cast<String>() ?? [];
    final title = data['eventTitle'] as String? ?? 'Événement';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Billet prêt à partager')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${tickets.length} billet(s) généré(s) pour $title',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...tickets.map((qr) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    QrImageView(data: qr, size: 160),
                    const SizedBox(height: 8),
                    Text(qr.substring(0, 12).toUpperCase(),
                        style: const TextStyle(
                            letterSpacing: 1.5,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Share.share(
                          'Voici ton billet Sunu Tikeu pour $title\nCode: $qr'),
                      icon: const Icon(Icons.share),
                      label: const Text('Partager'),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/organizer'),
            child: const Text('Retour au tableau de bord'),
          ),
        ],
      ),
    );
  }
}
