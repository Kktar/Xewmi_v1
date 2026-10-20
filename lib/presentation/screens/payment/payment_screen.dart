import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/repositories/ticket_repository.dart';
import '../../../services/payment_service.dart';
import '../../providers/auth_provider.dart';

final orderByIdProvider =
    FutureProvider.autoDispose.family<OrderModel?, String>((ref, orderId) {
  return ref.watch(ticketRepositoryProvider).getOrderById(orderId);
});

class PaymentScreen extends ConsumerStatefulWidget {
  final String orderId;
  const PaymentScreen({super.key, required this.orderId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String? _selectedMethod;
  bool _loading = false;

  final _methods = const [
    (id: 'wave', name: 'Wave', icon: Icons.waves, color: Color(0xFF1DC4FF)),
    (
      id: 'orange_money',
      name: 'Orange Money',
      icon: Icons.phone_android,
      color: Color(0xFFFF6600)
    ),
    (
      id: 'free_money',
      name: 'Free Money',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF00A651)
    ),
    (
      id: 'card',
      name: 'Carte bancaire',
      icon: Icons.credit_card,
      color: AppColors.primary
    ),
  ];

  Future<void> _pay(int amount) async {
    if (_selectedMethod == null) return;
    setState(() => _loading = true);

    try {
      final profile = ref.read(currentProfileProvider).valueOrNull;
      final paymentService = ref.read(paymentServiceProvider);

      final result = await paymentService.initiatePayDunya(
        orderId: widget.orderId,
        amountXof: amount,
        description: 'Billet Sunu Tikeu',
        customerName: profile?.displayName ?? 'Client',
        customerPhone: profile?.phone ?? '',
        customerEmail: profile?.email ?? 'client@sunutikeu.sn',
        returnUrl: 'https://sunutikeu.sn/payment/success',
        cancelUrl: 'https://sunutikeu.sn/payment/cancel',
        callbackUrl: 'https://YOUR_SUPABASE_FUNCTIONS/paydunya-webhook',
      );

      if (result.success && result.checkoutUrl != null) {
        await launchUrl(
          Uri.parse(result.checkoutUrl!),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Mode démo : si PayDunya n'est pas configuré, simuler le paiement
        if (mounted) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Mode démo'),
              content: Text(
                result.message ??
                    'Paiement non configuré.\nSimuler un paiement réussi de $amount ${AppConstants.currencySymbol} ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Simuler le paiement'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await ref.read(ticketRepositoryProvider).confirmPayment(
                  orderId: widget.orderId,
                  paymentMethod: _selectedMethod!,
                  paymentReference: 'DEMO-${DateTime.now().millisecondsSinceEpoch}',
                );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paiement confirmé !'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.go('/my-tickets');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    final currencyFmt = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: AppConstants.currencySymbol,
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Paiement')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Commande introuvable'));
          }
          final amount = order.totalAmount;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Montant
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Montant à payer',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFmt.format(amount),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    if (order.eventTitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        order.eventTitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choisissez votre moyen de paiement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Wave, Orange Money et Free Money sont les plus utilisés au Sénégal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ..._methods.map((m) {
                final selected = _selectedMethod == m.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMethod = m.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppColors.primaryLight : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: m.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(m.icon, color: m.color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            m.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle,
                              color: AppColors.primary),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: AppColors.success, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Paiement sécurisé via PayDunya / CinetPay. Vos données sont protégées.',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: orderAsync.maybeWhen(
        data: (order) {
          if (order == null) return null;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: ElevatedButton(
                onPressed: _selectedMethod != null && !_loading
                    ? () => _pay(order.totalAmount)
                    : null,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Payer ${NumberFormat.currency(locale: 'fr_FR', symbol: AppConstants.currencySymbol, decimalDigits: 0).format(order.totalAmount)}',
                      ),
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}
