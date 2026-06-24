# Anonym Flutter

Front-end Flutter de l'application Anonym.

## Prérequis

- Flutter SDK (stable)
- Dart SDK (fourni avec Flutter)
- Android Studio ou VS Code
- Émulateur Android/iOS ou appareil physique

## Installation

```bash
flutter pub get
```

## Environnements

L'app supporte 3 environnements via `--dart-define`:

- `APP_ENV=dev` (par défaut)
- `APP_ENV=staging`
- `APP_ENV=prod`

Variables disponibles:

- `APP_ENV`
- `API_BASE_URL`
- `API_BASE_URL_ANDROID`
- `API_BASE_URL_IOS`
- `API_BASE_URL_WINDOWS`
- `API_BASE_URL_WEB`
- `MAPBOX_ACCESS_TOKEN`
- `TLS_PINNING_ENABLED` (`true|false`, optionnel)
- `TLS_PINNED_CERT_SHA256` (liste CSV d'empreintes SHA-256, optionnel)
- `EXPOSE_BACKEND_ERRORS` (`true|false`, optionnel)

Fallback dev sans `--dart-define` (confort local uniquement):

- Android: `http://10.0.2.2:5000` (emulateur)
- iOS: `http://127.0.0.1:5000` (simulateur)
- Web/Desktop: `http://localhost:5000`

Recommande pour toute execution non-locale (device physique/CI): definir explicitement `API_BASE_URL*`.

## Lancement

### Développement (local)

```bash
flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=API_BASE_URL=http://localhost:5000 \
  --dart-define=MAPBOX_ACCESS_TOKEN=pk...
```

### Staging

```bash
flutter run \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://staging-api.anonym-app.com \
  --dart-define=MAPBOX_ACCESS_TOKEN=pk... \
  --dart-define=TLS_PINNED_CERT_SHA256=<fingerprint_sha256>
```

### Production (build release)

```bash
flutter build apk --release \
  --dart-define=APP_ENV=prod \
  --dart-define=API_BASE_URL=https://api.anonym-app.com \
  --dart-define=MAPBOX_ACCESS_TOKEN=pk... \
  --dart-define=TLS_PINNED_CERT_SHA256=<fingerprint_sha256>
```

## Sécurité

- En `staging` et `prod`, `AppConfig` exige une URL API en `https`.
- En `staging` et `prod`, le pinning TLS est activé par défaut sur plateformes natives (`dart:io`) et exige des empreintes SHA-256 valides.
- Sur Web, le pinning TLS applicatif n'est pas disponible (protection via HTTPS + validation TLS du navigateur).
- Le cleartext Android (`http`) est autorisé uniquement en `debug` manifest.
- Le manifest principal n'autorise pas le cleartext en release.
- Les messages d'erreur backend bruts sont masqués hors debug/dev.
- Le token Mapbox n'est plus hardcodé et doit être fourni via `--dart-define`.
- L'auth Socket.IO est basée sur les cookies de session (pas de duplication `Authorization`/`auth.token` côté client Flutter).
- Les cookies de session sont persistés uniquement sur Android/iOS (mémoire seulement sur desktop).

### Firebase Android (`google-services.json`)

Le fichier `android/app/google-services.json` est versionné pour simplifier les builds CI/CD Android.
La clé API Firebase qu'il contient n'est pas un secret applicatif suffisant à elle seule, mais elle doit être durcie côté console Firebase/GCP.

Checklist obligatoire:

1. Restreindre la clé API Android au package `com.anonym.front_flutter` + SHA-1/SHA-256 de signature.
2. Désactiver toutes les APIs Google inutilisées pour cette clé.
3. Vérifier des règles strictes Firestore/Storage (pas d'accès public non authentifié).
4. Activer quotas et alerting (usage anormal / pics).
5. Tourner la clé immédiatement en cas d'exposition suspecte.

### Politique de logs (production)

En production, les logs `info/warning/error` peuvent être émis pour l'observabilité, mais il est interdit d'y inclure:

- tokens/cookies/session IDs,
- payloads bruts contenant emails, messages privés ou coordonnées,
- traces d'erreurs backend contenant des données personnelles.

Règle d'équipe: logguer des identifiants techniques minimaux (ex: type d'erreur, code HTTP, ID interne non sensible) et privilégier la redaction/sanitization avant tout `AppLogger.*`.

## Qualité

### Analyse statique

```bash
flutter analyze
```

### Tests

```bash
flutter test
```

Tests ciblés utiles:

```bash
flutter test test/utils/app_config_test.dart
flutter test test/screens/support_feedback_misc_screen_test.dart
flutter test test/screens/friends_screen_test.dart
```

## Structure (résumé)

- `lib/screens` : écrans
- `lib/widgets` : composants UI
- `lib/providers` : état applicatif (Provider)
  - `*_provider.dart` : facade UI (expose un domaine a l'ecran)
  - `*_providers.dart` : modules internes de `AppProvider` (parts/services d'orchestration)
- `lib/services` : API/repositories/socket/push
- `lib/models` : modèles de données
- `lib/routes` : routing (`go_router`)
- `lib/utils` : config + helpers
- `test/` : tests unitaires, widgets, providers, services

## Documentation technique

- Architecture globale: `doc/ARCHITECTURE.md`
- Lifecycle providers: `doc/PROVIDER_LIFECYCLE.md`
- Contrat Socket.IO: `doc/SOCKET_EVENTS.md`

## Dépendances clés

- `provider`
- `go_router`
- `dio`
- `socket_io_client`
- `firebase_messaging`
- `mapbox_maps_flutter`

## Troubleshooting

- Erreur "Insecure API_BASE_URL": vérifier `APP_ENV` et passer une URL `https` en staging/prod.
- Erreur "Token Mapbox manquant": passer `--dart-define=MAPBOX_ACCESS_TOKEN=...`.
- Erreur de pinning TLS: vérifier `TLS_PINNED_CERT_SHA256` et l'empreinte du certificat serveur.
- Impossible de joindre l'API en mobile: vérifier l'IP LAN backend et réseau partagé appareil/PC.
- En dev, fallback non adapte a un device physique: passer `--dart-define=API_BASE_URL_ANDROID=http://<LAN_IP>:5000`.
- Problème de build: lancer `flutter clean && flutter pub get`.

## Note équipe

Si tu modifies des libellés FR dans l'UI, mets aussi à jour les tests widget concernés pour garder la CI verte.
