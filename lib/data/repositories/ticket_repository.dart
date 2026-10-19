import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../services/supabase_service.dart';
import '../models/ticket_model.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository();
});

class TicketRepository {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

  /// Crée une commande + billets en attente de paiement
  Future<OrderModel> createOrder({
    required String userId,
    required String eventId,
    required List<({String ticketTypeId, String name, int price, int qty})> items,
  }) async {
    final total = items.fold<int>(0, (s, i) => s + i.price * i.qty);

    final orderData = await _client.from('orders').insert({
      'user_id': userId,
      'event_id': eventId,
      'total_amount': total,
      'status': 'pending',
    }).select().single();

    final orderId = orderData['id'] as String;
    final ticketsToInsert = <Map<String, dynamic>>[];

    for (final item in items) {
      for (var i = 0; i < item.qty; i++) {
        ticketsToInsert.add({
          'order_id': orderId,
          'event_id': eventId,
          'ticket_type_id': item.ticketTypeId,
          'qr_code': _uuid.v4().replaceAll('-', ''),
          'status': 'pending',
          'price': item.price,
          'holder_name': null,
        });
      }
    }

    await _client.from('tickets').insert(ticketsToInsert);

    return OrderModel.fromJson({
      ...orderData,
      'tickets': ticketsToInsert,
    });
  }

  /// Marque la commande et les billets comme payés (appelé après webhook paiement)
  Future<void> confirmPayment({
    required String orderId,
    required String paymentMethod,
    required String paymentReference,
  }) async {
    await _client.from('orders').update({
      'status': 'paid',
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
    }).eq('id', orderId);

    await _client.from('tickets').update({
      'status': 'paid',
    }).eq('order_id', orderId);
  }

  Future<List<TicketModel>> getUserTickets(String userId) async {
    final data = await _client
        .from('tickets')
        .select('''
          *,
          orders!inner(user_id),
          events(title, venue, start_at),
          ticket_types(name)
        ''')
        .eq('orders.user_id', userId)
        .eq('status', 'paid')
        .order('created_at', ascending: false);

    return (data as List).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      map['event_title'] = map['events']?['title'];
      map['event_venue'] = map['events']?['venue'];
      map['event_start_at'] = map['events']?['start_at'];
      map['ticket_type_name'] = map['ticket_types']?['name'];
      return TicketModel.fromJson(map);
    }).toList();
  }

  Future<TicketModel?> getTicketByQr(String qrCode) async {
    final data = await _client
        .from('tickets')
        .select('*, events(title, venue, start_at), ticket_types(name)')
        .eq('qr_code', qrCode)
        .maybeSingle();
    if (data == null) return null;
    final map = Map<String, dynamic>.from(data);
    map['event_title'] = map['events']?['title'];
    map['event_venue'] = map['events']?['venue'];
    map['event_start_at'] = map['events']?['start_at'];
    map['ticket_type_name'] = map['ticket_types']?['name'];
    return TicketModel.fromJson(map);
  }

  Future<void> markTicketUsed(String ticketId) async {
    await _client.from('tickets').update({
      'status': 'used',
      'used_at': DateTime.now().toIso8601String(),
    }).eq('id', ticketId);
  }

  Future<List<TicketModel>> getEventTickets(String eventId) async {
    final data = await _client
        .from('tickets')
        .select('*, ticket_types(name)')
        .eq('event_id', eventId)
        .inFilter('status', ['paid', 'used'])
        .order('created_at', ascending: false);

    return (data as List).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      map['ticket_type_name'] = map['ticket_types']?['name'];
      return TicketModel.fromJson(map);
    }).toList();
  }

  /// Génération manuelle de billets par l'organisateur (gratuit / invité)
  Future<List<TicketModel>> generateComplimentaryTickets({
    required String eventId,
    required String ticketTypeId,
    required int quantity,
    required int price,
    String? holderName,
    String? holderPhone,
  }) async {
    // Créer une commande "cash" pour l'organisateur
    final userId = SupabaseService.currentUserId!;
    final orderData = await _client.from('orders').insert({
      'user_id': userId,
      'event_id': eventId,
      'total_amount': 0,
      'payment_method': 'cash',
      'status': 'paid',
    }).select().single();

    final orderId = orderData['id'] as String;
    final tickets = List.generate(quantity, (_) => {
          'order_id': orderId,
          'event_id': eventId,
          'ticket_type_id': ticketTypeId,
          'qr_code': _uuid.v4().replaceAll('-', ''),
          'status': 'paid',
          'price': price,
          'holder_name': holderName,
          'holder_phone': holderPhone,
        });

    final inserted = await _client.from('tickets').insert(tickets).select();
    return (inserted as List)
        .map((e) => TicketModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
