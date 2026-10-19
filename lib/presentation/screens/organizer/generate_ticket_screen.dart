import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/ticket_repository.dart';
import '../event/event_detail_screen.dart';

class GenerateTicketScreen extends ConsumerStatefulWidget {
  final String eventId;
  const GenerateTicketScreen({super.key, required this.eventId});
  @override
  ConsumerState<GenerateTicketScreen> createState() =>
      _GenerateTicketScreenState();
}

class _GenerateTicketScreenState extends ConsumerState<GenerateTicketScreen> {
  String? _typeId;
  int _qty = 1;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _generate() async {
    if (_typeId == null) return;
    final event = ref.read(eventDetailProvider(widget.eventId)).valueOrNull;
    if (event == null) return;
    final type = event.ticketTypes.firstWhere((t) => t.id == _typeId);

    setState(() => _loading = true);
    try {
      final tickets = await ref
          .read(ticketRepositoryProvider)
          .generateComplimentaryTickets(
            eventId: widget.eventId,
            ticketTypeId: _typeId!,
            quantity: _qty,
            price: type.price,
            holderName:
                _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
            holderPhone:
                _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          );
      if (mounted) {
        context.push('/organizer/ticket-ready', extra: {
          'tickets': tickets.map((t) => t.qrCode).toList(),
          'eventTitle': event.title,
        });
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
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Générer un billet')),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (event) {
          if (event == null) return const SizedBox();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Type de billet',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...event.ticketTypes.map((t) => RadioListTile<String>(
                    value: t.id,
                    // ignore: deprecated_member_use
                    groupValue: _typeId,
                    // ignore: deprecated_member_use
                    onChanged: (v) => setState(() => _typeId = v),
                    title: Text(t.name),
                    subtitle: Text('${t.price} FCFA'),
                  )),
              const SizedBox(height: 16),
              const Text('Quantité',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  IconButton(
                    onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_qty',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  IconButton(
                    onPressed: () => setState(() => _qty++),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nom du titulaire (optionnel)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Téléphone (optionnel)', prefixText: '+221 '),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _typeId != null && !_loading ? _generate : null,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Générer le(s) billet(s)'),
              ),
            ],
          );
        },
      ),
    );
  }
}
