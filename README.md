# Sunu Tikeu

Application de billetterie événementielle (Flutter + Supabase) — Sénégal.

## Fonctionnalités

- Parcours invité (accueil sans login)
- Login téléphone / Google au moment d'acheter
- **Mes billets** — liste des billets achetés + e-ticket QR
- Organisateur : KYC (NINEA, pièce d'identité), dashboard ventes, acheteurs, e-ticket manuel
- Paiements : Wave, Orange Money, Free Money (PayDunya) + **mode démo**
- Scanner QR, e-tickets
- Navigation complète (accueil, explorer, billets, organisateur, profil)

## Corrections v1 (app opérationnelle)

- Écran **Mes billets** créé et branché (nav centrale + profil)
- Bottom navigation corrigée
- E-ticket charge les vraies données Supabase
- Paiement utilise le montant réel de la commande + simulation démo
- Route `/my-tickets` protégée par auth
- Dossiers `assets/` créés

## Prérequis

- Flutter 3.24+
- Android SDK 36
- JDK 17
- Projet Supabase

## Démarrage rapide

```bash
cd Xewmi_v1
# 1) Compléter la plateforme Android si besoin
flutter create . --platforms=android

# 2) IMPORTANT : remettre les flags anti-AGP9 dans android/gradle.properties
#    android.newDsl=false
#    android.builtInKotlin=false
# et compileSdk=36, minSdk=23 dans android/app/build.gradle.kts

# 3) Clés Supabase
# Éditer lib/core/constants/app_constants.dart

# 4) SQL
# Exécuter supabase/migrations/001_*.sql puis 002_*.sql puis 003_*.sql

# 5) Lancer
flutter pub get
flutter run
```

## Structure

```
lib/
  core/          theme, router, constants
  data/          models, repositories
  presentation/  screens, widgets, providers
  services/      supabase, payment
supabase/
  migrations/
```

## Dépannage build Android

Voir `docs/BUILD_ANDROID.md`
