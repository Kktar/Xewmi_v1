# Config Android Sunu Tikeu (anti-erreurs Gradle)

## Versions validées pour Flutter récent

| Outil | Version | Fichier |
|-------|---------|---------|
| Gradle | 8.14 | `android/gradle/wrapper/gradle-wrapper.properties` |
| AGP | 8.11.1 | `android/settings.gradle.kts` |
| Kotlin | 2.2.20 | `android/settings.gradle.kts` |
| compileSdk | 36 | `android/app/build.gradle.kts` |
| minSdk | 23 | `android/app/build.gradle.kts` |
| targetSdk | 36 | `android/app/build.gradle.kts` |

## Flags obligatoires (`android/gradle.properties`)

```
android.newDsl=false
android.builtInKotlin=false
```

Sans ça, AGP 9 casse le plugin Flutter.

## Installation

```bash
unzip sunu_tikeu.zip
cd sunu_tikeu
flutter create . --platforms=android   # complète les icônes mipmap si besoin
# Puis recoller gradle.properties flags si flutter create les écrase
flutter pub get
flutter run
```

Si `flutter create` réécrit les fichiers Android, **remettez** :
1. `android/gradle.properties` avec `android.newDsl=false`
2. `compileSdk = 36` et `minSdk = 23` dans `app/build.gradle.kts`

## Supabase

Renseigner dans `lib/core/constants/app_constants.dart` :
- supabaseUrl
- supabaseAnonKey
