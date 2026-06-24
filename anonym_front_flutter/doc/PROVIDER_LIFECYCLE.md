# Provider Lifecycle

## AuthProvider (`lib/providers/auth_providers.dart`)

## Etat cle

1. `_user`: utilisateur courant (`null` si non connecte).
2. `_isBootstrapping`: phase de restauration de session au demarrage.
3. `_isBusy`: mutation auth en cours (login/signup/logout/...).
4. `_errorMessage`, `_infoMessage`: feedback UI.

## Cycle

1. Construction -> `bootstrap()` auto.
2. `bootstrap()`:
   - hydrate la session locale,
   - appelle `me()`,
   - met a jour `_user`.
3. `login/signup/confirm...`:
   - active `_isBusy`,
   - appelle `AuthRepository`,
   - met `_user` ou `_errorMessage`.
4. `logout()`:
   - tente logout serveur,
   - nettoie session locale,
   - met `_user=null`.

## Session expiree

`ApiClient` peut invoquer `setSessionExpiredHandler`:

1. nettoyage local,
2. deconnexion locale,
3. message utilisateur.

## AppProvider (`lib/providers/app_providers.dart` + parts)

Convention de nommage:

1. `*_provider.dart`: facade exposee aux ecrans.
2. `*_providers.dart`: modules internes relies via `part` a `AppProvider`.

## Responsabilites

1. Etat social (amis, demandes, utilisateurs bloques).
2. Etat channels/messages.
3. Etat boutique/inventaire/factures.
4. Presence, geoloc live, notifications in-app.
5. Orchestration socket et push.

## Decoupage interne (refresh)

Les appels de refresh applicatif ne vivent plus directement dans une seule
extension massive. Ils sont delegates a des services internes:

1. `_SocialRefreshDomainService`
2. `_ChannelsRefreshDomainService`
3. `_CommerceRefreshDomainService`

`AppProvider` conserve la coordination globale (`refreshAll`) mais delegue
les details metier a ces services.

## Decoupage interne (operations metier)

Les operations social/channels/account ne sont plus portees directement
par des extensions volumineuses. Elles sont deleguees a:

1. `_SocialDomainService`
2. `_ChannelsDomainService`
3. `_AccountDomainService`

Les extensions `AppProviderSocialX`, `AppProviderChannelsX` et
`AppProviderAccountX` jouent le role de facades stables pour l'UI.

## Decoupage interne (cross-cutting)

Les helpers transverses qui etaient dans `AppProviderLifecyclePushX` ont ete
sortis dans des services dedies:

1. `_AppProviderMutationService` (`_wrap`)
2. `_AppProviderParsingService` (`_toInt`, `_parseDate`, format temporel)
3. `_AppProviderNotificationService` (push/in-app notifications + persistence
   des IDs lus)

## Signalement des changements (scoped)

`AppProvider` expose des listenables dedies:

1. `orchestratorListenable`
2. `socialListenable`
3. `channelsListenable`
4. `commerceListenable`
5. `presenceListenable`
6. `notificationsListenable`

Chaque facade (`SocialProvider`, `ChannelsProvider`, etc.) s'abonne uniquement
au domaine utile, ce qui evite des invalidations UI transverses quand un autre
domaine change.

## Cycle utilisateur

1. Auth change (`_handleAuthChange`):
   - sans user: reset + disconnect.
   - user connecte: boot temps reel.
2. Boot (`_bootForLoggedInUser`):
   - connect socket avec auth fraiche,
   - start keepalive session,
   - `refreshAll()`,
   - setup push,
   - applique presence lifecycle.
3. Logout/switch user:
   - envoi invisible best-effort,
   - disconnect socket,
   - clear etat.

## Lifecycle Flutter

`AppProvider` implemente `WidgetsBindingObserver`:

1. `resumed` -> presence online.
2. `inactive/paused` -> presence idle.
3. `detached` -> invisible + disconnect.

## Strategie d'erreur

Actions metier via `_wrap(...)` (delegue a `_AppProviderMutationService`):

1. optionnellement active spinner (`_isSubmitting`),
2. reset erreur precedente,
3. catch -> message via `ApiErrorParser`,
4. `notifyListeners()`.
