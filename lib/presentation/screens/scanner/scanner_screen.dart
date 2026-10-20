import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/repositories/ticket_repository.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _processing = false;
  String? _lastResult;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty || code == _lastResult) return;

    setState(() {
      _processing = true;
      _lastResult = code;
    });

    try {
      final ticket =
          await ref.read(ticketRepositoryProvider).getTicketByQr(code);
      if (ticket == null) {
        _showResult(false, 'Billet introuvable');
      } else if (ticket.isUsed) {
        _showResult(false, 'Billet déjà utilisé');
      } else if (!ticket.isValid) {
        _showResult(false, 'Billet non valide (non payé ou annulé)');
      } else {
        await ref.read(ticketRepositoryProvider).markTicketUsed(ticket.id);
        final name = ticket.ticketTypeName ?? 'Billet';
        final holder = ticket.holderName;
        _showResult(
          true,
          holder != null && holder.isNotEmpty
              ? 'Valide — $name ($holder)'
              : 'Billet valide — $name',
        );
      }
    } catch (e) {
      final appError = AppError.from(e);
      _showResult(false, appError.message);
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showResult(bool ok, String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner un billet'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _processing ? AppColors.success : Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Text(
              _processing ? 'Vérification...' : 'Alignez le QR code',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
