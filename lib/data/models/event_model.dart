import 'package:equatable/equatable.dart';

enum EventStatus { draft, published, cancelled, completed }

class TicketTypeModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int price; // en FCFA
  final int quantity;
  final int sold;
  final bool isActive;

  const TicketTypeModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    this.sold = 0,
    this.isActive = true,
  });

  int get remaining => quantity - sold;
  bool get isSoldOut => remaining <= 0;

  factory TicketTypeModel.fromJson(Map<String, dynamic> json) {
    return TicketTypeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: json['price'] as int,
      quantity: json['quantity'] as int,
      sold: json['sold'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'quantity': quantity,
        'sold': sold,
        'is_active': isActive,
      };

  @override
  List<Object?> get props => [id, name, price, quantity, sold];
}

class EventModel extends Equatable {
  final String id;
  final String organizerId;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final String category;
  final String venue;
  final String city;
  final DateTime startAt;
  final DateTime? endAt;
  final EventStatus status;
  final List<TicketTypeModel> ticketTypes;
  final int totalTickets;
  final int ticketsSold;
  final DateTime createdAt;
  final String? organizerName;

  const EventModel({
    required this.id,
    required this.organizerId,
    required this.title,
    this.description,
    this.coverImageUrl,
    required this.category,
    required this.venue,
    required this.city,
    required this.startAt,
    this.endAt,
    this.status = EventStatus.draft,
    this.ticketTypes = const [],
    this.totalTickets = 0,
    this.ticketsSold = 0,
    required this.createdAt,
    this.organizerName,
  });

  int get remainingTickets => totalTickets - ticketsSold;
  bool get isSoldOut => remainingTickets <= 0;
  bool get isLive => status == EventStatus.published && startAt.isAfter(DateTime.now());

  int get minPrice {
    if (ticketTypes.isEmpty) return 0;
    return ticketTypes.map((t) => t.price).reduce((a, b) => a < b ? a : b);
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final ticketsJson = json['ticket_types'] as List<dynamic>? ?? [];
    return EventModel(
      id: json['id'] as String,
      organizerId: json['organizer_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      category: json['category'] as String? ?? 'Autres',
      venue: json['venue'] as String? ?? '',
      city: json['city'] as String? ?? '',
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: json['end_at'] != null ? DateTime.parse(json['end_at'] as String) : null,
      status: _parseStatus(json['status'] as String?),
      ticketTypes: ticketsJson
          .map((e) => TicketTypeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalTickets: json['total_tickets'] as int? ?? 0,
      ticketsSold: json['tickets_sold'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      organizerName: json['organizer_name'] as String? ??
          (json['profiles'] is Map ? (json['profiles'] as Map)['full_name'] : null),
    );
  }

  static EventStatus _parseStatus(String? s) {
    switch (s) {
      case 'published':
        return EventStatus.published;
      case 'cancelled':
        return EventStatus.cancelled;
      case 'completed':
        return EventStatus.completed;
      default:
        return EventStatus.draft;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizer_id': organizerId,
        'title': title,
        'description': description,
        'cover_image_url': coverImageUrl,
        'category': category,
        'venue': venue,
        'city': city,
        'start_at': startAt.toIso8601String(),
        'end_at': endAt?.toIso8601String(),
        'status': status.name,
        'total_tickets': totalTickets,
        'tickets_sold': ticketsSold,
        'created_at': createdAt.toIso8601String(),
      };

  EventModel copyWith({
    String? title,
    String? description,
    String? coverImageUrl,
    String? category,
    String? venue,
    String? city,
    DateTime? startAt,
    DateTime? endAt,
    EventStatus? status,
    List<TicketTypeModel>? ticketTypes,
  }) {
    return EventModel(
      id: id,
      organizerId: organizerId,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      category: category ?? this.category,
      venue: venue ?? this.venue,
      city: city ?? this.city,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      status: status ?? this.status,
      ticketTypes: ticketTypes ?? this.ticketTypes,
      totalTickets: totalTickets,
      ticketsSold: ticketsSold,
      createdAt: createdAt,
      organizerName: organizerName,
    );
  }

  @override
  List<Object?> get props => [id, title, startAt, status];
}
