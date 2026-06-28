# Anonym

## Description
Anonym est un projet visant à créer un réseau social de discussion en ligne tout en préservant les données des utilisateurs de l'application. 
Ce projet propose un système de messagerie privée basé sur IRC ainsi qu'un mécanisme de modération rigoureux avec un système de signalement et une boutique qui permet aux utilisateurs d’acheter des éléments de personnalisation pour leurs profils ainsi qu'un système de réputation et un système de classement pour les communautés public.

## Table des matières
1. [Guide d'installation local](#installation-local)
2. [Guide d'installation Docker](#docker)
3. [Guide CI](#guide-ci)
4. [Guide pour récupérer les différentes documentations jsDocs et Swagger](#documentations)

## Guide d'utilisation flutter pour générer l'apk en local 
flutter build apk `
  --dart-define=MAPBOX_ACCESS_TOKEN=pk.ton_token_mapbox `
  --dart-define=API_BASE_URL_ANDROID=http://TON_IP:5000

## Guide d'installation local
1. Assurez-vous d'avoir [Node.js](https://nodejs.org/), npm, Sequelize, et MySQL avec un serveur. 
Pour Linux, utilisez Apache; pour macOS, utilisez WAMP ou une alternative; pour Windows, utilisez WAMP ou une autre solution.
2. Clonez le dépôt :
```bash
git clone https://github.com/Lukas-Bouhlel/anonym.git
```
3. Installer les différentes dépendances
```bash
cd anonym-back-end
npm install
cd anonym-front-end
npm install
```
Ajoutez un fichier .env pour le frontend et le backend, .env.production et .env.preprod pour le frontend. La configuration des différentes variables d'environnement est présente dans le fichier .env.example.
N'oubliez pas de générer de nouveaux certificats SSL avec OpenSSL dans les différents répertoires du frontend et du backend.
Structure des dossiers : Ajoutez un sous-dossier articles dans le dossier uploads du backend pour stocker les images des différents produits de la boutique, ainsi qu'un sous-dossier avatars dans profiles (dans uploads) pour les photos de profil des utilisateurs.

### Guide d'installation Docker
1. Assurez-vous d'avoir Docker et Docker Compose installés sur votre machine et accessibles via le CLI, ainsi que Docker Desktop.

2. Installez le projet sur Docker : Rendez-vous dans le dossier parent "Anonym" et utilisez cette commande pour construire le conteneur, les volumes et les images pour la prod et la preprod :
```bash
docker-compose -f docker-compose.preprod.yml --env-file .env.preprod up -d --build
docker-compose -f docker-compose.prod.yml --env-file .env.production up -d --build 
```
Pour supprimer les builds, utilisez la commande suivante :
```bash
docker-compose -f docker-compose.preprod.yml --env-file .env.preprod down
docker-compose -f docker-compose.prod.yml --env-file .env.production down
```

## Guide CI
Ce projet utilise GitHub Actions pour la continuité d'intégration. 
Les tests sont exécutés à chaque push et pull requests sur la branche principale. 
Les étapes incluent, pour le frontend et le backend :
1. Connexion à une base de données créée pour les tests.
2. Génération de la migration de la base de données via Sequelize.
3. Génération de certificats SSL pour l'exécution des tests.
4. Vérification du formatage du code.
5. Génération de la documentation.
6. Exécution des tests unitaires.
7. Build de l'application front-end.
8. Vérification de la sécurité des différentes dépendances avec Snyk.

Pour plus d'informations, consultez le fichier `.github/workflows/ci.yml`.

## Guide pour récupérer les différentes documentations jsDocs et Swagger
### jsDocs
Pour générer la documentation jsDocs, exécutez la commande suivante dans le répertoire du frontend ou du backend du projet :
```bash
npm run generate-doc
```
Ensuite, ouvrez dans un navigateur le fichier index.html présent dans le dossier docs.

### Swagger
Pour la documentation de l'API, elle est disponible dans le fichier présent dans le répertoire anonym-backend/app/utils/swagger.yaml. 
Pour afficher son contenu lorsque l'application est démarrée, vous pouvez vous rendre sur la page suivante avec un compte ayant le rôle SUPER_ADMIN ou ADMIN : https://localhost:5000/api/admin/api-docs/

### Droits d'auteur
© Lukas Bouhlel
