# Solidification Sunu Tikeu

## Flux organisateur
1. Connexion Google (ou téléphone)
2. Dossier organisateur `/organizer/kyc` : prénom, nom, naissance, NINEA, CNI
3. status pending → approved (SQL admin)
4. Publication d'événement uniquement si KYC approved

## Client
- google_email + whatsapp sur profiles

## SQL
- migrations/001 + 002
- bucket storage `id-documents` (privé)

## Approuver KYC
UPDATE organizer_kyc SET status = 'approved', reviewed_at = NOW() WHERE user_id = 'UUID';
