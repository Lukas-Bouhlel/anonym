# Monitoring Prometheus - Anonym

Ce document décrit le branchement de Prometheus sur les métriques backend Anonym.

## Principe

Le backend expose les métriques Prometheus sur `/metrics` avec `prom-client`.

En production, l'accès est protégé par `METRICS_TOKEN`. Prometheus n'appelle pas l'URL publique Nginx : il scrape directement le service Docker interne `backend:5000`, avec un bearer token lu depuis un fichier local non versionné.

## Installation sur le VPS

Générer un token :

```bash
openssl rand -hex 32
```

Ajouter la même valeur dans l'environnement backend :

```env
METRICS_TOKEN=valeur_generee
```

Créer le fichier secret utilisé par Prometheus :

```bash
mkdir -p secrets
printf '%s' 'valeur_generee' > secrets/metrics_token.txt
chmod 600 secrets/metrics_token.txt
```

Recréer le backend pour charger `METRICS_TOKEN` :

```bash
docker-compose -f docker-compose.prod.yml --env-file .env.production up -d --force-recreate backend
```

Démarrer Prometheus et Alertmanager avec le compose de production et l'override monitoring :

```bash
docker-compose -f docker-compose.prod.yml -f docker-compose.monitoring.yml --env-file .env.production up -d prometheus alertmanager
```

## Vérifications

Sans token, l'accès backend doit être refusé :

```bash
curl -i http://127.0.0.1:5000/metrics
```

Avec token, les métriques doivent être retournées :

```bash
curl -i -H "x-metrics-token: valeur_generee" http://127.0.0.1:5000/metrics
```

Depuis Prometheus, vérifier la target :

```bash
curl http://127.0.0.1:9090/api/v1/targets
```

La target `anonym-backend` doit être en état `up`.

Vérifier les alertes Prometheus :

```bash
curl http://127.0.0.1:9090/api/v1/rules
curl http://127.0.0.1:9090/api/v1/alerts
```

Vérifier Alertmanager :

```bash
curl http://127.0.0.1:9093/api/v2/status
curl http://127.0.0.1:9093/api/v2/alerts
```

## Alertes configurées

| Alerte | Condition | Durée | Sévérité | Finalité |
| --- | --- | --- | --- | --- |
| `AnonymBackendDown` | Target Prometheus `up == 0` | 1 min | Critique | Détecter une indisponibilité backend |
| `AnonymBackendHighP95Latency` | P95 HTTP > 750 ms | 5 min | Warning | Détecter une dégradation de performance |
| `AnonymBackendHighErrorRate` | Erreurs 5xx > 1 % | 5 min | Critique | Détecter une anomalie applicative |
| `AnonymBackendHighMemoryUsage` | RSS Node.js > 512 Mio | 10 min | Warning | Détecter une pression mémoire |
| `AnonymBackendHighRequestVolume` | Plus de 20 req/s | 10 min | Warning | Détecter un trafic anormal ou une charge élevée |

## Sécurité

Les ports Prometheus et Alertmanager sont publiés uniquement sur localhost :

```yaml
ports:
  - "127.0.0.1:9090:9090"
  - "127.0.0.1:9093:9093"
```

Ils ne sont donc pas accessibles publiquement sans tunnel SSH ou reverse proxy explicitement protégé.

## Canal de notification

Alertmanager reçoit les alertes automatiquement et les expose sur son API locale. Pour envoyer les alertes vers un canal externe, ajouter ensuite un receiver email, Slack, Discord ou webhook dans `alertmanager/alertmanager.yml`.
