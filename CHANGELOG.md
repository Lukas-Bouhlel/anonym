# Changelog

## v1.1.0 - 2026-08-24

### Changé
- PR #234 - Devlop (`52f9dba2`)
- `b53b0d4f` - feat(android): automatiser le déploiement AAB sur Google Play et préserver les redirections de réinitialisation du mot de passe
- `063ac915` - Mise à jour de la version de browserslist
- `af72b891` - mise à jour de la version d'artillery
- `32594ead` - mise à jour du lint avec un intercepteur d'erreurs asynchrones du décodage SVG.

### Pull Requests déployées
- PR #234 - Devlop depuis `Lukas-Bouhlel/devlop` (`52f9dba2`)

### Périmètre Git
- Changements inclus depuis `v1.0.9` jusqu’à `HEAD`.

## v1.0.9 - 2026-08-06

### Corrigé
- `4cea3dc5` - fix(mobile): polish search inputs and reset deep links

### Changé
- PR #225 - Devlop (`81d36a6f`)

### Pull Requests déployées
- PR #225 - Devlop depuis `Lukas-Bouhlel/devlop` (`81d36a6f`)

### Périmètre Git
- Changements inclus depuis `v1.0.8` jusqu’à `HEAD`.

## v1.0.8 - 2026-08-06

### Corrige
- Recentrage vertical du placeholder et du texte saisi dans les champs de recherche de l'application mobile.
- Ajout d'un espacement coherent entre l'icone de recherche et le texte dans les barres de recherche Conversations, Chercher et Rejoindre.
- Correction du lien de reinitialisation de mot de passe pour ouvrir l'application mobile via deep link sur mobile, avec fallback web sur navigateur desktop.
- Compatibilite des builds debug Android avec les emulateurs `x86_64`, tout en conservant le filtrage `arm64-v8a` pour les builds non-debug.

### Validation
- `flutter analyze`
- `flutter build apk --debug --no-pub`
- `npm test -- --runTestsByPath app/tests/test_unitaires/resetPasswordBridge.test.js --runInBand`
- `npm run lint`

### Pull Requests deployees
- A renseigner apres creation de la PR.

Ce fichier est maintenu à chaque release. Chaque entrée doit indiquer les changements livrés, les Pull Requests déployées, les issues/anomalies associées et les validations réalisées.

## v1.0.8 - 2026-08-05

### Documentation
- PR #222 - update changelog (`e1a5982f`)
- `63bb58e3` - update changelog

### Pull Requests déployées
- PR #222 - update changelog depuis `Lukas-Bouhlel/devlop` (`e1a5982f`)

### Périmètre Git
- Changements inclus depuis `v1.0.7` jusqu’à `HEAD`.

## v1.0.7 - 2026-08-05

### Ajouté
- Ajout d’un contrôle pré-déploiement dans `cd_deploy_to_production` pour vérifier la version du `CHANGELOG.md` avant le build et le déploiement production.
- Alignement du build frontend sur Node.js `22.22.0`.
- Ajout d’une politique `restart: unless-stopped` aux services Docker de production.

### Correctifs documentés
- Prévention d’un déploiement production non versionné ou utilisant un tag Git déjà existant sur un autre commit.
- Réduction du risque qu’un service Docker reste arrêté après un arrêt brutal du conteneur.

### Validation
- Vérification syntaxique des workflows GitHub Actions et du fichier `docker-compose.prod.yml`.
- Contrôle attendu : le workflow CD bloque avant le build/deploy si la version du changelog est incohérente.
- Tag Git créé automatiquement uniquement après un déploiement production valide.

### Pull Requests déployées
- PR #219 - Sécurisation du versionnement avant déploiement production.

## v1.0.6 - 2026-08-05

### Changé
- Optimisation de la CI : la validation Flutter est exécutée uniquement en cas de changement mobile ou de lancement manuel du workflow.
- Ajout d’un job de détection des chemins modifiés pour éviter les builds APK inutiles.
- Les étapes de sécurité Flutter sont ignorées lorsqu’aucun fichier mobile n’est modifié.

### Correctifs documentés
- Réduction du temps de validation CI pour les changements backend, web, documentation ou monitoring.
- Conservation d’une validation Flutter complète lorsqu’un changement touche `anonym_front_flutter/` ou lorsque le workflow est lancé manuellement.

### Validation
- Workflow CI final compatible avec un job Flutter en état `skipped`.
- Vérification syntaxique du workflow GitHub Actions.

### Pull Requests déployées
- PR #216 - Optimisation de la validation Flutter dans la CI.

## v1.0.5 - 2026-08-05

### Ajouté
- Automatisation de la génération du `CHANGELOG.md` à partir de l’historique Git et des Pull Requests mergées.
- Automatisation de la création du tag Git de release après déploiement production réussi, à partir de la dernière version renseignée dans `CHANGELOG.md`.
- Ajout d’une supervision Prometheus pour collecter automatiquement les métriques backend exposées par `/metrics`.
- Ajout d’Alertmanager pour centraliser les alertes techniques.
- Ajout de règles d’alerte Prometheus sur :
  - la disponibilité du backend ;
  - le P95 des temps de réponse ;
  - le taux d’erreurs HTTP 5xx ;
  - la mémoire Node.js ;
  - le volume de requêtes.
- Ajout d’un fichier `docker-compose.monitoring.yml` pour déployer Prometheus et Alertmanager avec Docker Compose.
- Ajout de la documentation `docs/monitoring-prometheus.md`.

### Sécurité
- Protection de l’endpoint `/metrics` par `METRICS_TOKEN`.
- Support de l’en-tête `x-metrics-token` et de `Authorization: Bearer` pour l’accès aux métriques.
- Configuration de Prometheus pour scraper le backend via le réseau Docker interne, sans exposition publique via Nginx.
- Ajout des secrets monitoring dans `.gitignore`.

### Validation
- Vérification en production de la target Prometheus `anonym-backend` en état `UP`.
- Vérification des règles d’alertes chargées dans Prometheus.
- Test backend d’observabilité validé avec 5 tests passés.

### Documentation Bloc 4
- Mise à jour du dossier Bloc 4 avec les preuves de supervision, d’alerte et de sécurisation de `/metrics`.

### Pull Requests déployées
- PR #212 - Déploiement production de la supervision Prometheus/Alertmanager.
- PR #211 - Intégration preprod des changements de supervision.

### Issues et anomalies associées
- Issue #213 - `ANO-PROD-2026-07-02` : consignation de l’anomalie des uploads non persistants.
- PR #172 - `fix/prod-uploads-volume` : correctif de persistance des uploads.
- Commit `62a03902` - `Persist production uploads volume`.

## v1.0.3 - 2026-07-02

### Corrigé
- Persistance des fichiers uploadés en production grâce au volume Docker `./anonym-back-end/uploads:/app/uploads`.

### Pull Requests déployées
- PR #172 - Livraison du correctif vers `preprod`.
- PR #173 - Livraison du correctif dans le flux de release.

### Validation
- Vérification HTTP d’un fichier `/uploads/...` servi en `200 OK`.
- Vérification des logs backend après redéploiement : migrations Sequelize, connexion DB et écoute sur le port `5000`.
