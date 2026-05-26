# Test Suite Structure

## Folders

- `validators/`: règles de validation des formulaires (auth, mot de passe).
- `utils/`: fonctions utilitaires pures (dates, présence, payloads, parsing d'erreurs, URLs).
- `models/`: parsing JSON et helpers des modèles.
- `widgets/`: logique widget isolée (ex. helpers de carte).

## Commands

```bash
flutter test
```

Mode detaille (1 ligne par etape de test):

```bash
flutter test -r expanded -j 1
```

Mode detaille + coverage:

```bash
flutter test -r expanded -j 1 --coverage
```

Script PowerShell avec recap coverage par fichier:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\test_verbose.ps1
```

Le script affiche 2 metriques:
- `TOTAL`: coverage global (tous les fichiers traces par `flutter test --coverage`).
- `UNIT`: coverage unitaire (hors couches UI/integration lourdes: `screens/`, `socket_service`, `push_notification_service`, `anonym_map_view_io`, etc.).

Pour lancer un seul fichier:

```bash
flutter test test/utils/media_url_test.dart
```

