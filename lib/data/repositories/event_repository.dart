import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../models/event_model.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

class EventRepository {
  final _client = SupabaseService.client;

  Future<List<EventModel>> getPublishedEvents({
    String? category,
    String? city,
    String? search,
    int offset = 0,
    int limit = 20,
  }) async {
    // Les filtres (.eq, .ilike, .or) doivent être appliqués AVANT .order()
    var query = _client
        .from('events')
        .select('*, ticket_types(*), profiles!organizer_id(full_name)')
        .eq('status', 'published')
        .gte('start_at', DateTime.now().toIso8601String());

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    if (city != null && city.isNotEmpty) {
      query = query.ilike('city', '%$city%');
    }
    if (search != null && search.isNotEmpty) {
      query = query.or(
        'title.ilike.%$search%,city.ilike.%$search%,venue.ilike.%$search%',
      );
    }

    final data = await query
        .order('start_at', ascending: true)
        .range(offset, offset + limit - 1);

    return (data as List)
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EventModel?> getEventById(String id) async {
    final data = await _client
        .from('events')
        .select('*, ticket_types(*), profiles!organizer_id(full_name)')
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return EventModel.fromJson(data);
  }

  Future<List<EventModel>> getOrganizerEvents(String organizerId) async {
    final data = await _client
        .from('events')
        .select('*, ticket_types(*)')
        .eq('organizer_id', organizerId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EventModel> createEvent({
    required String organizerId,
    required String title,
    String? description,
    String? coverImageUrl,
    required String category,
    required String venue,
    required String city,
    required DateTime startAt,
    DateTime? endAt,
    required List<Map<String, dynamic>> ticketTypes,
  }) async {
    final eventData = await _client
        .from('events')
        .insert({
          'organizer_id': organizerId,
          'title': title,
          'description': description,
          'cover_image_url': coverImageUrl,
          'category': category,
          'venue': venue,
          'city': city,
          'start_at': startAt.toIso8601String(),
          'end_at': endAt?.toIso8601String(),
          'status': 'draft',
          'total_tickets':
              ticketTypes.fold<int>(0, (s, t) => s + (t['quantity'] as int)),
        })
        .select()
        .single();

    final eventId = eventData['id'] as String;

    if (ticketTypes.isNotEmpty) {
      final types = ticketTypes
          .map((t) => {
                ...t,
                'event_id': eventId,
              })
          .toList();
      await _client.from('ticket_types').insert(types);
    }

    return (await getEventById(eventId))!;
  }

  Future<void> publishEvent(String eventId) async {
    await _client
        .from('events')
        .update({'status': 'published'}).eq('id', eventId);
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    await _client.from('events').update(updates).eq('id', eventId);
  }

  Future<String> uploadCoverImage(String path, List<int> bytes) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('event-covers').uploadBinary(
          fileName,
          bytes as dynamic,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return _client.storage.from('event-covers').getPublicUrl(fileName);
  }
}
