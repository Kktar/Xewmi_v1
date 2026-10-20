import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';

/// Service d'intégration des agrégateurs de paiement Sénégal
/// Supporté : PayDunya (recommandé) et CinetPay
/// Méthodes : Wave, Orange Money, Free Money, Cartes

enum PaymentProvider { paydunya, cinetpay }

class PaymentResult {
  final bool success;
  final String? checkoutUrl;
  final String? transactionId;
  final String? message;

  const PaymentResult({
    required this.success,
    this.checkoutUrl,
    this.transactionId,
    this.message,
  });
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

class PaymentService {
  /// Initialise un paiement via PayDunya (recommandé pour le Sénégal)
  /// Docs : https://paydunya.com/developers
  Future<PaymentResult> initiatePayDunya({
    required String orderId,
    required int amountXof,
    required String description,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String returnUrl,
    required String cancelUrl,
    String? callbackUrl,
  }) async {
    const isTest = AppConstants.paydunyaMode == 'test';
    const baseUrl = isTest
        ? 'https://app.paydunya.com/sandbox-api/v1'
        : 'https://app.paydunya.com/api/v1';

    final body = {
      'invoice': {
        'total_amount': amountXof,
        'description': description,
      },
      'store': {
        'name': 'Sunu Tikeu',
      },
      'custom_data': {
        'order_id': orderId,
      },
      'actions': {
        'cancel_url': cancelUrl,
        'return_url': returnUrl,
        if (callbackUrl != null) 'callback_url': callbackUrl,
      },
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/checkout-invoice/create'),
        headers: {
          'Content-Type': 'application/json',
          'PAYDUNYA-MASTER-KEY': AppConstants.paydunyaMasterKey,
          'PAYDUNYA-PRIVATE-KEY': AppConstants.paydunyaPrivateKey,
          'PAYDUNYA-TOKEN': AppConstants.paydunyaToken,
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['response_code'] == '00') {
        return PaymentResult(
          success: true,
          checkoutUrl: data['response_text'] as String?,
          transactionId: data['token'] as String?,
        );
      }

      return PaymentResult(
        success: false,
        message: data['response_text'] as String? ?? 'Erreur PayDunya',
      );
    } catch (e) {
      return PaymentResult(success: false, message: e.toString());
    }
  }

  /// Initialise un paiement via CinetPay
  /// Docs : https://docs.cinetpay.com
  Future<PaymentResult> initiateCinetPay({
    required String orderId,
    required int amountXof,
    required String description,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String returnUrl,
    required String notifyUrl,
  }) async {
    final body = {
      'apikey': AppConstants.cinetpayApiKey,
      'site_id': AppConstants.cinetpaySiteId,
      'transaction_id': orderId,
      'amount': amountXof,
      'currency': 'XOF',
      'description': description,
      'customer_name': customerName,
      'customer_surname': customerName,
      'customer_email': customerEmail,
      'customer_phone_number': customerPhone,
      'customer_address': 'Dakar',
      'customer_city': 'Dakar',
      'customer_country': 'SN',
      'customer_state': 'SN',
      'customer_zip_code': '00000',
      'notify_url': notifyUrl,
      'return_url': returnUrl,
      'channels': 'ALL', // Wave, OM, Free Money, Card
    };

    try {
      final response = await http.post(
        Uri.parse('https://api-checkout.cinetpay.com/v2/payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['code'] == '201') {
        final paymentData = data['data'] as Map<String, dynamic>;
        return PaymentResult(
          success: true,
          checkoutUrl: paymentData['payment_url'] as String?,
          transactionId: paymentData['payment_token'] as String?,
        );
      }

      return PaymentResult(
        success: false,
        message: data['message'] as String? ?? 'Erreur CinetPay',
      );
    } catch (e) {
      return PaymentResult(success: false, message: e.toString());
    }
  }

  /// Vérifie le statut d'une transaction PayDunya
  Future<bool> verifyPayDunya(String token) async {
    const isTest = AppConstants.paydunyaMode == 'test';
    const baseUrl = isTest
        ? 'https://app.paydunya.com/sandbox-api/v1'
        : 'https://app.paydunya.com/api/v1';

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/checkout-invoice/confirm/$token'),
        headers: {
          'PAYDUNYA-MASTER-KEY': AppConstants.paydunyaMasterKey,
          'PAYDUNYA-PRIVATE-KEY': AppConstants.paydunyaPrivateKey,
          'PAYDUNYA-TOKEN': AppConstants.paydunyaToken,
        },
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['status'] == 'completed';
    } catch (_) {
      return false;
    }
  }
}
