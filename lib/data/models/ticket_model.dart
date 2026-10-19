import 'package:equatable/equatable.dart';

enum TicketStatus { pending, paid, used, cancelled, refunded }
enum PaymentMethod { wave, orangeMoney, freeMoney, card, cash }

class OrderModel extends Equatable {
  final String id;
  final String userId;
  final String eventId;
  final int totalAmount;
  final PaymentMethod? paymentMethod;
  final String? paymentReference;
  final TicketStatus status;
  final DateTime createdAt;
  final List<TicketModel> tickets;
  final String? eventTitle;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.totalAmount,
    this.paymentMethod,
    this.paymentReference,
    this.status = TicketStatus.pending,
    required this.createdAt,
    this.tickets = const [],
    this.eventTitle,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final ticketsJson = json['tickets'] as List<dynamic>? ?? [];
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      totalAmount: json['total_amount'] as int,
      paymentMethod: _parseMethod(json['payment_method'] as String?),
      paymentReference: json['payment_reference'] as String?,
      status: _parseStatus(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      tickets: ticketsJson
          .map((e) => TicketModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      eventTitle: json['event_title'] as String?,
    );
  }

  static PaymentMethod? _parseMethod(String? s) {
    switch (s) {
      case 'wave':
        return PaymentMethod.wave;
      case 'orange_money':
        return PaymentMethod.orangeMoney;
      case 'free_money':
        return PaymentMethod.freeMoney;
      case 'card':
        return PaymentMethod.card;
      case 'cash':
        return PaymentMethod.cash;
      default:
        return null;
    }
  }

  static TicketStatus _parseStatus(String? s) {
    switch (s) {
      case 'paid':
        return TicketStatus.paid;
      case 'used':
        return TicketStatus.used;
      case 'cancelled':
        return TicketStatus.cancelled;
      case 'refunded':
        return TicketStatus.refunded;
      default:
        return TicketStatus.pending;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'event_id': eventId,
        'total_amount': totalAmount,
        'payment_method': paymentMethod?.name,
        'payment_reference': paymentReference,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, status, totalAmount];
}

class TicketModel extends Equatable {
  final String id;
  final String orderId;
  final String eventId;
  final String ticketTypeId;
  final String? ticketTypeName;
  final String qrCode;
  final TicketStatus status;
  final DateTime? usedAt;
  final String? holderName;
  final String? holderPhone;
  final int price;
  final DateTime createdAt;
  // Joined
  final String? eventTitle;
  final String? eventVenue;
  final DateTime? eventStartAt;

  const TicketModel({
    required this.id,
    required this.orderId,
    required this.eventId,
    required this.ticketTypeId,
    this.ticketTypeName,
    required this.qrCode,
    this.status = TicketStatus.pending,
    this.usedAt,
    this.holderName,
    this.holderPhone,
    required this.price,
    required this.createdAt,
    this.eventTitle,
    this.eventVenue,
    this.eventStartAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      eventId: json['event_id'] as String,
      ticketTypeId: json['ticket_type_id'] as String,
      ticketTypeName: json['ticket_type_name'] as String?,
      qrCode: json['qr_code'] as String,
      status: OrderModel._parseStatus(json['status'] as String?),
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'] as String)
          : null,
      holderName: json['holder_name'] as String?,
      holderPhone: json['holder_phone'] as String?,
      price: json['price'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      eventTitle: json['event_title'] as String?,
      eventVenue: json['event_venue'] as String?,
      eventStartAt: json['event_start_at'] != null
          ? DateTime.parse(json['event_start_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'event_id': eventId,
        'ticket_type_id': ticketTypeId,
        'qr_code': qrCode,
        'status': status.name,
        'used_at': usedAt?.toIso8601String(),
        'holder_name': holderName,
        'holder_phone': holderPhone,
        'price': price,
        'created_at': createdAt.toIso8601String(),
      };

  bool get isValid => status == TicketStatus.paid;
  bool get isUsed => status == TicketStatus.used;

  @override
  List<Object?> get props => [id, qrCode, status];
}
