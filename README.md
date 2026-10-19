# Sunu Tikeu

Application de billetterie événementielle (Flutter + Supabase) — Sénégal.

## Fonctionnalités

- Parcours invité (accueil sans login)
- Login téléphone / Google au moment d'acheter
- Organisateur : KYC (NINEA, pièce d'identité), dashboard ventes, acheteurs, e-ticket manuel
- Paiements (prévu) : Wave, Orange Money, Free Money
- Scanner QR, e-tickets

## Prérequis

- Flutter 3.24+
- Android SDK 36
- JDK 17
- Projet Supabase

## Démarrage rapide

```bash
cd sunu_tikeu
# 1) Compléter la plateforme Android si besoin
flutter create . --platforms=android

# 2) IMPORTANT : remettre les flags anti-AGP9 dans android/gradle.properties
#    android.newDsl=false
#    android.builtInKotlin=false
# et compileSdk=36, minSdk=23 dans android/app/build.gradle.kts

# 3) Clés Supabase
# Éditer lib/core/constants/app_constants.dart

# 4) SQL
# Exécuter supabase/migrations/001_*.sql puis 002_*.sql

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
# Xewmi_v1
