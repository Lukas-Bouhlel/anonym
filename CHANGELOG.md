# Changelog

Ce fichier est maintenu à chaque release. Chaque entrée doit indiquer les changements livrés, les Pull Requests déployées, les issues/anomalies associées et les validations réalisées.

## v1.0.5 - 2026-08-05

### Ajouté
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
