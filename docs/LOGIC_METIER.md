# Logique métier Sunu Tikeu

## Client
- Connexion : téléphone (OTP), Google, ou mode test
- **Téléphone obligatoire** pour recevoir le e-ticket (SMS/WhatsApp)
- Parcours libre jusqu'à l'achat → login demandé

## Organisateur
### KYC obligatoire avant publication
- Prénom, nom, date de naissance
- **NINEA**
- **Téléphone**
- **Pièce d'identité** (photo claire ou PDF)
- Statut : pending → approved (admin SQL)

### Événement payant
- Types de billets (prix, quantité)
- Publication si KYC approved
- Ventes + liste acheteurs + e-ticket manuel

### Événement entrée libre
- Pas de vente de billets
- **Frais de publication : 50 000 FCFA** (`publish_fee_paid`)
- Invitations (codes) : envoyer / valider à l'entrée
- Trigger SQL bloque publication si frais non payés

## Simulation tests
1. Mode test → Client → acheter billet (après seed SQL)
2. Mode test → Organisateur → KYC → créer événement
3. Approuver KYC :
```sql
UPDATE organizer_kyc SET status = 'approved', reviewed_at = NOW()
WHERE user_id = 'UUID';
```
4. Free event publish fee :
```sql
UPDATE events SET publish_fee_paid = true, publish_fee_amount = 50000,
  publish_fee_paid_at = NOW(), status = 'published'
WHERE id = 'EVENT_UUID';
```
