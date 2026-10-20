# Config Android Sunu Tikeu

## Embedding Flutter v2 (obligatoire)

Le projet utilise **uniquement** l'embedding Android v2 :
- `MainActivity` extends `io.flutter.embedding.android.FlutterActivity`
- `AndroidManifest` contient `<meta-data android:name="flutterEmbedding" android:value="2" />`

## Versions

| Outil | Version |
|-------|---------|
| Gradle | 8.12 |
| AGP | 8.7.3 |
| Kotlin | 2.1.0 |
| compileSdk | 36 |
| minSdk | 23 |
| targetSdk | 36 |

## Flags (`android/gradle.properties`)

```
android.useAndroidX=true
android.newDsl=false
android.builtInKotlin=false
```

## Première installation

```bash
cd Xewmi_v1

# 1) Complète les fichiers manquants (gradlew, éventuellement icônes)
flutter create . --platforms=android

# 2) Si flutter create a écrasé gradle.properties, remettre :
#    android.newDsl=false
#    android.builtInKotlin=false

# 3) Vérifier MainActivity.kt :
#    package com.sunutikeu.sunu_tikeu
#    import io.flutter.embedding.android.FlutterActivity
#    class MainActivity : FlutterActivity()

# 4) Lancer
flutter pub get
flutter run
```

## Erreur « deleted Android v1 embedding »

Causes fréquentes :
1. Dossier `android/` incomplet ou vide
2. `MainActivity` utilise encore `io.flutter.app.FlutterActivity` (v1)
3. Manifest sans `flutterEmbedding=2`

Solution : ce projet est déjà en v2. Relancer `flutter create . --platforms=android` puis `flutter clean && flutter pub get && flutter run`.
