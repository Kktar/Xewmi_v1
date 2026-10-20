import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';

/// Gestion centralisée des erreurs (réseau, auth, métier)
class AppError {
  final String message;
  final String? code;
  final bool isRetryable;

  const AppError({
    required this.message,
    this.code,
    this.isRetryable = true,
  });

  factory AppError.from(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid') && msg.contains('otp')) {
        return const AppError(
          message: 'Code incorrect. Vérifiez le SMS et réessayez.',
          code: 'invalid_otp',
          isRetryable: true,
        );
      }
      if (msg.contains('expired')) {
        return const AppError(
          message: 'Code expiré. Demandez un nouveau code.',
          code: 'otp_expired',
          isRetryable: true,
        );
      }
      if (msg.contains('rate') || msg.contains('limit')) {
        return const AppError(
          message: 'Trop de tentatives. Attendez quelques minutes.',
          code: 'rate_limit',
          isRetryable: false,
        );
      }
      return AppError(
        message: 'Authentification : ${error.message}',
        code: error.statusCode,
        isRetryable: true,
      );
    }

    if (error is PostgrestException) {
      final code = error.code;
      if (code == '23505') {
        return const AppError(
          message: 'Cet élément existe déjà.',
          code: 'duplicate',
          isRetryable: false,
        );
      }
      if (code == '42501' || code == 'PGRST301') {
        return const AppError(
          message: 'Accès refusé. Connectez-vous ou vérifiez vos droits.',
          code: 'permission',
          isRetryable: false,
        );
      }
      if (code == 'PGRST116') {
        return const AppError(
          message: 'Élément introuvable.',
          code: 'not_found',
          isRetryable: false,
        );
      }
      return AppError(
        message: error.message.isNotEmpty
            ? error.message
            : 'Erreur serveur. Réessayez plus tard.',
        code: code,
        isRetryable: true,
      );
    }

    if (error is AuthRetryableFetchException ||
        error.toString().contains('SocketException') ||
        error.toString().contains('ClientException') ||
        error.toString().contains('Failed host lookup') ||
        error.toString().contains('Network is unreachable')) {
      return const AppError(
        message: 'Pas de connexion internet. Vérifiez votre réseau.',
        code: 'network',
        isRetryable: true,
      );
    }

    final s = error.toString();
    if (s.length > 120) {
      return AppError(
        message: 'Une erreur est survenue. Réessayez.',
        code: 'unknown',
        isRetryable: true,
      );
    }
    return AppError(message: s, isRetryable: true);
  }
}

/// Helpers UI pour afficher les erreurs
class ErrorUi {
  ErrorUi._();

  static void showSnack(BuildContext context, Object error,
      {String? fallback}) {
    final appError = AppError.from(error);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(fallback ?? appError.message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        action: appError.isRetryable
            ? null
            : SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
      ),
    );
  }

  static Widget errorView({
    required Object error,
    VoidCallback? onRetry,
    String? title,
  }) {
    final appError = AppError.from(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              appError.code == 'network'
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Oups…',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appError.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (onRetry != null && appError.isRetryable) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget emptyView({
    required String title,
    required String subtitle,
    IconData icon = Icons.inbox_outlined,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
