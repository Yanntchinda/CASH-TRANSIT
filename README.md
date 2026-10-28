# Saint Jacquet Distribution

Application de démonstration pour consulter des départs de fret aérien et maritime, demander une réservation et gérer les départs et réservations depuis un espace administrateur.

## Lancer l’application

Ouvrez `index.html` dans un navigateur ou, depuis ce dossier, lancez :

```sh
python3 -m http.server 8000
```

Puis rendez-vous sur `http://localhost:8000`. Un client peut créer son compte depuis l’écran d’accueil. Pour découvrir l’espace administrateur, utilisez l’identifiant `admin` et le mot de passe initial `Admin@2026`.

## Limites de la démonstration

Les départs et réservations préchargés sont des exemples. Toutes les données, y compris les comptes et réservations, restent dans le stockage local du navigateur : elles ne sont pas partagées entre utilisateurs ou appareils. Les paiements ne sont pas encaissés par l’application. L’authentification et le stockage côté navigateur ne conviennent pas à une utilisation en production avec des données réelles ; un serveur sécurisé et une base de données sont nécessaires.

## Version Android (APK de démonstration)

Le dossier `android/` contient une application Android qui embarque la version web, servie par `WebViewAssetLoader` sous une origine HTTPS locale. La compilation GitHub Actions (`Build Android APK`) produit un APK **debug**, signé avec la clé de debug de l'environnement de compilation : il est destiné aux essais, pas à la publication sur le Play Store. Il nécessite Android 6.0 (API 23) ou ultérieur.

Pour construire localement, installez JDK 17, le SDK Android 35 et Gradle 8.9, puis exécutez `gradle -p android assembleDebug`. Le fichier est créé dans `android/app/build/outputs/apk/debug/app-debug.apk`. L'application est autonome pour les écrans et données d'exemple ; les liens WhatsApp et e-mail ouvrent une application externe. Les mêmes limites de démonstration et de stockage local s'appliquent.
