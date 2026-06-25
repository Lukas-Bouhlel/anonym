# Architecture Anonym Flutter

## 1) Vue d'ensemble

L'application suit une architecture en couches:

1. `screens/` + `widgets/`: presentation UI.
2. `providers/`: orchestration d'etat et logique applicative.
3. `services/`: acces reseau (Dio), Socket.IO, push, repositories.
4. `models/`: contrats de donnees (JSON <-> objets).
5. `utils/`: configuration, parsing erreurs, helpers.

## 2) Demarrage

Point d'entree: `lib/main.dart`.

Sequence:

1. Initialisation Flutter et Firebase Messaging.
2. Creation de `ApiClient` (Dio + cookies + securite transport).
3. Construction des repositories (`AuthRepository`, `ChannelRepository`, etc.).
4. Injection via `Provider`/`ChangeNotifierProvider`.
5. Lancement de `AnonymApp`.

## 3) Flux principal

### Authentification

1. `AuthProvider` bootstrap la session (`hydrateSession` + `/api/account`).
2. Les cookies de session sont geres par `ApiClient`.
3. En cas de `401`, interception + tentative de refresh `/api/auth/refresh`.

### Donnees metier

1. UI appelle un provider de domaine:
   - `SocialProvider`
   - `ChannelsProvider`
   - `PresenceProvider`
   - `NotificationsProvider`
   - `CommerceProvider`
2. Chaque provider de domaine est une facade fine sur `AppProvider`.
3. `AppProvider` reste l'orchestrateur central et delegue aux repositories.
4. Les refresh metier sont maintenant delegates a des services internes
   specialises:
   - `_SocialRefreshDomainService`
   - `_ChannelsRefreshDomainService`
   - `_CommerceRefreshDomainService`
5. Les operations metier `social/channels/account` sont elles aussi delegates
   a des services dedies:
   - `_SocialDomainService`
   - `_ChannelsDomainService`
   - `_AccountDomainService`
6. Cette extraction reduit la taille des extensions `AppProvider*X` et limite
   les regressions transverses lors des evolutions de domaine.
7. Les helpers transverses (mutations, parsing, notifications in-app) sont
   egalement extrais dans des services dedies:
   - `_AppProviderMutationService`
   - `_AppProviderParsingService`
   - `_AppProviderNotificationService`
8. `AppOrchestratorProvider` expose les actions globales (`refreshAll`, etat
   de bootstrapping, erreur applicative).
9. Les facades de domaine ecoutent des listenables scopes (`socialListenable`,
   `channelsListenable`, `presenceListenable`, `commerceListenable`,
   `notificationsListenable`, `orchestratorListenable`) au lieu d'un
   `addListener` global.
10. L'UI privilegie `Selector`/`context.select` pour limiter les rebuilds.

### Convention de nommage providers

1. `*_provider.dart`: facade publique consommee par l'UI (un domaine clair).
2. `*_providers.dart`: fichiers part de `AppProvider` (orchestration interne).
3. Cette separation permet de garder l'API UI stable pendant les refactors internes.

### Temps reel

1. `AppProviderRealtimeX` ouvre la socket via `SocketService`.
2. `RealtimeCoordinator` pilote keepalive session + recovery socket.
3. `AppProviderRealtimeEventHandler` traite les evenements entrants
   (messages, social, presence, location) et orchestre les refresh debounce.
4. La logique geoloc/camera de l'ecran d'accueil est isolee dans
   `HomeLocationController` (`lib/controllers/home_location_controller.dart`).

## 4) Securite

1. `MAPBOX_ACCESS_TOKEN` doit etre fourni par `--dart-define`.
2. HTTPS obligatoire en `staging/prod`.
3. Pinning TLS natif configure via:
   - `TLS_PINNING_ENABLED`
   - `TLS_PINNED_CERT_SHA256`
   - (Web: pas de pinning applicatif, delegation au navigateur)
4. Les erreurs backend detaillees sont masquees hors debug/dev
   (`EXPOSE_BACKEND_ERRORS=false` par defaut en non-dev).
5. Socket.IO reutilise les cookies de session pour l'authentification.
6. En dev, les fallbacks reseau ne reposent plus sur une IP LAN machine-specifique:
   - Android emulateur: `http://10.0.2.2:5000`
   - iOS simulateur: `http://127.0.0.1:5000`
   - Web/Desktop: `http://localhost:5000`

## 5) Tests

La suite contient des tests unitaires et widgets:

1. `test/services`: repositories + client API.
2. `test/providers`: logique providers.
3. `test/controllers`: controleurs UI techniques (ex: geoloc/carte).
4. `test/models` et `test/utils`: parsing, helpers, validateurs.
5. `test/screens` et `test/widgets`: comportements UI critiques.

## 6) Architecture Decisions (ADR court)

### ADR-001: Realtime lifecycle hors AppProvider

- Date: 31 mai 2026
- Decision: extraire le cycle de vie realtime technique dans
  `RealtimeCoordinator` (keepalive, reconnect, recovery auth).
- Rationale: reduire la taille et le couplage de `AppProvider`,
  isoler les risques de regression reseau/session.
- Consequence: code realtime plus testable et points d'entree mieux separes.

### ADR-002: Event handlers realtime dedies

- Date: 31 mai 2026
- Decision: centraliser les handlers socket dans
  `AppProviderRealtimeEventHandler`.
- Rationale: separer orchestration d'etat et traitement evenementiel.
- Consequence: maintenance plus simple, extension des events plus sure.

### ADR-003: Garde-fou CI Flutter obligatoire

- Date: 31 mai 2026
- Decision: ajouter un job CI Flutter (`pub get`, `analyze`, `test`).
- Rationale: eviter les regressions Flutter non detectees sur PR.
- Consequence: feedback plus rapide et pipeline plus fiable.

### ADR-004: Signaux de changement scopes par domaine

- Date: 31 mai 2026
- Decision: introduire `AppDomainSignals` et brancher chaque provider de
  domaine sur un `Listenable` dedie.
- Rationale: reduire les rebuilds inutiles causes par `notifyListeners()`
  global et limiter le couplage UI -> AppProvider monolithique.
- Consequence: meilleures performances percuees et maintenance plus sure
  (chaque domaine reagit uniquement a ses mutations).

### ADR-005: Extraction des refresh metier en services dedies

- Date: 31 mai 2026
- Decision: extraire les blocs de refresh `social/channels/commerce`
  dans des services internes prives de `AppProvider`.
- Rationale: reduire la responsabilite directe de `AppProvider` et isoler
  les evolutions de chaque domaine.
- Consequence: surface de maintenance plus petite dans les extensions,
  meilleure lisibilite des flux de refresh et tests plus stables.

### ADR-006: Extensions `AppProvider*X` en facades minces

- Date: 31 mai 2026
- Decision: deplacer la logique metier des extensions `social/channels/account`
  vers des services de domaine prives.
- Rationale: eviter des extensions trop volumineuses et clarifier les
  responsabilites metier.
- Consequence: `AppProvider` garde la coordination globale, tandis que les
  blocs metier evoluent de facon plus isolee et testable.

### ADR-007: Extraction des helpers transverses

- Date: 1 juin 2026
- Decision: extraire `wrap/parse/notifications` dans des services internes
  dedies pour reduire la taille de `AppProviderLifecyclePushX`.
- Rationale: isoler les concerns transverses et eviter qu'un seul module
  concentre a la fois lifecycle, push, notification et gestion d'erreur.
- Consequence: code plus lisible, responsibilities plus claires et points
  de test plus simples a cibler.
