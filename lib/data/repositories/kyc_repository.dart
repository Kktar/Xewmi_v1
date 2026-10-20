import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

final kycRepositoryProvider = Provider<KycRepository>((ref) => KycRepository());

class KycRepository {
  final _client = SupabaseService.client;

  Future<Map<String, dynamic>?> getMyKyc() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    return await _client
        .from('organizer_kyc')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
  }

  Future<bool> isApproved() async {
    final kyc = await getMyKyc();
    return kyc != null && kyc['status'] == 'approved';
  }

  Future<String> uploadIdDocument(String fileName, Uint8List bytes, String contentType) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/$fileName';
    await _client.storage.from('id-documents').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    // privé : on stocke le path, pas une URL publique
    return path;
  }

  Future<void> submitKyc({
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String ninea,
    required String idDocumentUrl,
    required String idDocumentType,
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('organizer_kyc').upsert({
      'user_id': uid,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      'ninea': ninea,
      'id_document_url': idDocumentUrl,
      'id_document_type': idDocumentType,
      'status': 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    });
    await logActivity(
      action: 'kyc_submitted',
      entityType: 'organizer_kyc',
      metadata: {'ninea': ninea},
    );
  }

  Future<void> logActivity({
    required String action,
    String? eventId,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('activity_logs').insert({
      'actor_id': uid,
      'event_id': eventId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'metadata': metadata ?? {},
    });
  }

  /// Acheteurs d'un événement (commandes payées + billets)
  Future<List<Map<String, dynamic>>> getEventBuyers(String eventId) async {
    final data = await _client
        .from('tickets')
        .select(
          'id, status, price, holder_name, holder_phone, created_at, used_at, '
          'ticket_types(name), orders(id, payment_method, payment_reference, user_id, profiles:user_id(full_name, phone, whatsapp, email, google_email))',
        )
        .eq('event_id', eventId)
        .inFilter('status', ['paid', 'used'])
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<List<Map<String, dynamic>>> getMyActivity({int limit = 50}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await _client
        .from('activity_logs')
        .select()
        .eq('actor_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data as List);
  }
}
