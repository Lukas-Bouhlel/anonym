# Securite backend - points de controle

## Secrets non versionnes

- Les fichiers `.env`, `.env.production`, `.env.preprod` et variantes locales sont ignores par Git.
- Les fichiers de signature mobile (`*.jks`, `*.keystore`, `*.p12`, `*.p8`, `anonym_front_flutter/android/key.properties`) sont ignores par Git.
- Les secrets CI/CD doivent rester dans GitHub Secrets : `JWT_SECRET`, `STRIPE_SECRET_KEY`, variables DB, SMTP, Snyk, cle SSH de deploiement.
- Le fichier Firebase Android versionne n'est pas considere comme un secret applicatif suffisant seul, mais la cle doit etre restreinte dans Firebase/GCP.

## Logs sans donnees sensibles

- Le helper `app/utils/security.js` masque les champs sensibles avant log : authorization, cookie, password, token, refreshToken, session, secret, stripe.
- Les flux sensibles d'authentification et de paiement utilisent ce helper pour les erreurs serveur.
- Les logs doivent rester techniques : scope, type d'erreur, ID interne si necessaire, jamais de token/cookie/mot de passe/payload prive.

## Erreurs production non bavardes

- `sendServerError` renvoie le message detaille hors production.
- En `NODE_ENV=production`, la reponse HTTP 500 renvoie uniquement le message de secours prevu par le controleur.
- Les details restent dans les logs rediges pour l'exploitation.

## Dependances auditees

- GitHub Actions execute Snyk sur le frontend web, le backend et Flutter.
- GitHub Actions execute `npm audit --audit-level=high` sur le frontend web et le backend.
- Les dependances a risque eleve doivent etre corrigees avant fusion vers les branches de livraison.

## Rotation et expiration des tokens

- Les access tokens ont une duree courte via `JWT_ACCESS_TTL`, par defaut 15 minutes.
- Les refresh tokens sont stockes haches en base et expirent via `JWT_REFRESH_TTL_DAYS`, par defaut 7 jours.
- Chaque refresh revoque le refresh token precedent et emet un nouveau refresh token.
- Le logout revoque le refresh token actif.
- Le nettoyage periodique supprime les refresh tokens expires ou revoques anciens via `refreshTokenCleanup`.
