# Déploiement Android sur Google Play

Le workflow `.github/workflows/cd.yml` construit deux artefacts Android signés :

- un APK, conservé pour la distribution directe depuis le VPS ;
- un Android App Bundle (`.aab`), destiné à Google Play.

Le package publié est `com.anonym.front_flutter`. Il doit être strictement identique à celui créé dans la Play Console.

## Clés et certificats

Google Play App Signing utilise deux clés distinctes :

1. La **clé d'upload** est le fichier privé `upload-keystore.jks`. La CD l'utilise pour signer l'AAB avant son envoi. Elle est reconstruite dans GitHub Actions à partir des secrets `ANDROID_KEYSTORE_*`. Le JKS et ses mots de passe ne doivent jamais être commités.
2. La **clé de signature d'application** est conservée par Google Play. Le fichier `.der` téléchargeable depuis la Play Console contient uniquement son certificat public. Il ne permet pas de signer une application et n'est nécessaire ni sur le VPS, ni dans GitHub Actions, ni dans l'APK/AAB.

Conserver éventuellement le `.der` dans un coffre documentaire privé. Pour Firebase, Google OAuth ou Android App Links, enregistrer l'empreinte SHA-1/SHA-256 de la **clé de signature d'application** affichée par Play, pas le fichier sur le serveur.

## Initialisation obligatoire dans Google Play

Avant le premier envoi automatisé :

1. Créer l'application dans la Play Console avec le package `com.anonym.front_flutter`.
2. Compléter les éléments obligatoires : fiche Play Store, politique de confidentialité, sécurité des données, accès à l'application, classification et pays de distribution.
3. Charger manuellement un premier AAB signé dans une release brouillon. Cette étape associe définitivement le package et la clé d'upload à l'application Play.
4. Dans **Intégrité de l'application**, vérifier que l'empreinte de la clé d'upload correspond au JKS utilisé par la CD. Ne pas la confondre avec la clé de signature d'application affichée dans la capture Play.

Pour afficher l'empreinte locale de la clé d'upload :

```powershell
keytool -list -v `
  -keystore anonym_front_flutter/android/app/upload-keystore.jks `
  -alias <ANDROID_KEY_ALIAS>
```

## Autoriser GitHub Actions

1. Dans Google Cloud, activer **Google Play Android Developer API**.
2. Créer un compte de service et télécharger sa clé JSON.
3. Dans **Play Console > Utilisateurs et autorisations**, inviter l'adresse du compte de service.
4. Limiter son accès à l'application Anonym et lui donner les droits nécessaires pour gérer les releases de production.
5. Dans GitHub, créer l'environnement `google-play-production`. Ajouter une règle d'approbation si une validation humaine avant publication est souhaitée.
6. Ajouter dans cet environnement le secret `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, contenant l'intégralité du JSON du compte de service.

La clé JSON est un secret privé. Elle ne doit pas être enregistrée dans le dépôt ni sur le VPS.

## Première exécution contrôlée

Depuis **Actions > cd_deploy_to_production > Run workflow** :

1. activer `publish_google_play` ;
2. choisir `production` ;
3. choisir `draft` pour que la CD charge l'AAB sans le publier immédiatement ;
4. vérifier puis envoyer la release en validation depuis la Play Console.

Chaque build reçoit automatiquement :

- un `versionName` issu de la première version du `CHANGELOG.md` ;
- un `versionCode` unique calculé à partir du numéro d'exécution GitHub Actions.

## Publication automatique

Après validation du premier cycle :

1. créer la variable GitHub `GOOGLE_PLAY_AUTO_PUBLISH=true` ;
2. créer `GOOGLE_PLAY_TRACK=production` ;
3. créer `GOOGLE_PLAY_RELEASE_STATUS=completed`.

Chaque déploiement réussi de `main` construira alors l'AAB et l'enverra automatiquement sur la piste de production. Google Play conserve son processus de revue : l'API automatise l'envoi, mais ne contourne pas la validation Google.

Pour conserver une approbation humaine, ne pas créer `GOOGLE_PLAY_AUTO_PUBLISH` et déclencher la publication via `workflow_dispatch`, ou ajouter des approbateurs obligatoires à l'environnement `google-play-production`.

## Références

- https://support.google.com/googleplay/android-developer/answer/9842756
- https://developers.google.com/android-publisher/getting_started
- https://developer.android.com/guide/app-bundle
