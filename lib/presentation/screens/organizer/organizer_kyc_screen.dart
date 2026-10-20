import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/kyc_repository.dart';
import '../../../data/repositories/auth_repository.dart';

/// Formulaire obligatoire pour devenir organisateur / publier
class OrganizerKycScreen extends ConsumerStatefulWidget {
  const OrganizerKycScreen({super.key});

  @override
  ConsumerState<OrganizerKycScreen> createState() => _OrganizerKycScreenState();
}

class _OrganizerKycScreenState extends ConsumerState<OrganizerKycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _ninea = TextEditingController();
  final _phone = TextEditingController();
  DateTime? _dob;
  Uint8List? _docBytes;
  String? _docName;
  String _docType = 'image';
  bool _loading = false;
  Map<String, dynamic>? _existing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final kyc = await ref.read(kycRepositoryProvider).getMyKyc();
    if (kyc != null && mounted) {
      setState(() {
        _existing = kyc;
        _firstName.text = kyc['first_name'] ?? '';
        _lastName.text = kyc['last_name'] ?? '';
        _ninea.text = kyc['ninea'] ?? '';
        if (kyc['date_of_birth'] != null) {
          _dob = DateTime.tryParse(kyc['date_of_birth'].toString());
        }
      });
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _ninea.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _docBytes = bytes;
      _docName = x.name;
      _docType = 'image';
    });
  }

  Future<void> _pickCamera() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _docBytes = bytes;
      _docName = x.name;
      _docType = 'image';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date de naissance obligatoire')),
      );
      return;
    }
    final isResubmit = _existing != null && _existing!['status'] == 'rejected';
    if (_docBytes == null && (_existing == null || isResubmit)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ajoutez une pièce d\'identité (photo ou PDF)')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      String docUrl = _existing?['id_document_url'] ?? '';
      if (_docBytes != null) {
        final ext = _docType == 'pdf' ? 'pdf' : 'jpg';
        final ct = _docType == 'pdf' ? 'application/pdf' : 'image/jpeg';
        docUrl = await ref.read(kycRepositoryProvider).uploadIdDocument(
              'cni_${DateTime.now().millisecondsSinceEpoch}.$ext',
              _docBytes!,
              ct,
            );
      }

      await ref.read(kycRepositoryProvider).submitKyc(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            dateOfBirth: _dob!,
            ninea: _ninea.text.trim(),
            idDocumentUrl: docUrl,
            idDocumentType: _docType,
          );

      // Mettre à jour profil
      await ref.read(authRepositoryProvider).updateProfile(
            fullName: '${_firstName.text.trim()} ${_lastName.text.trim()}',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dossier KYC envoyé. Validation avant publication.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
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
    final status = _existing?['status'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: const Text('Dossier organisateur',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (status != null) ...[
              _StatusBanner(
                  status: status, reason: _existing?['rejection_reason']),
              const SizedBox(height: 16),
            ],
            const Text(
              'Informations obligatoires pour publier un événement',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'Prénom *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Nom *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date de naissance *'),
              subtitle: Text(
                _dob == null
                    ? 'Sélectionner'
                    : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime(1995, 1, 1),
                  firstDate: DateTime(1950),
                  lastDate:
                      DateTime.now().subtract(const Duration(days: 365 * 18)),
                );
                if (d != null) setState(() => _dob = d);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ninea,
              decoration: const InputDecoration(
                labelText: 'NINEA *',
                hintText: 'Numéro d\'identification nationale',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Obligatoire';
                if (v.trim().length < 5) return 'NINEA invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone *',
                prefixText: '+221 ',
                hintText: '77 000 00 00',
              ),
              validator: (v) {
                if (v == null || v.trim().length < 9) {
                  return 'Numéro obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Pièce d\'identité (CNI / Passeport) *',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Photo claire ou PDF lisible',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Photo'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickCamera,
                    icon: const Icon(Icons.camera_outlined),
                    label: const Text('Appareil photo'),
                  ),
                ),
              ],
            ),
            if (_docName != null) ...[
              const SizedBox(height: 8),
              Text('Fichier : $_docName',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.success)),
            ] else if (_existing?['id_document_url'] != null) ...[
              const SizedBox(height: 8),
              const Text('Document déjà déposé',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading || status == 'approved' ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(status == 'approved'
                        ? 'Dossier déjà validé'
                        : 'Envoyer le dossier'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  final String? reason;
  const _StatusBanner({required this.status, this.reason});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'approved' => (
          AppColors.success,
          'Dossier approuvé — vous pouvez publier'
        ),
      'rejected' => (
          AppColors.error,
          'Dossier refusé${reason != null ? ' : $reason' : ''}'
        ),
      _ => (AppColors.warning, 'En cours de validation'),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
