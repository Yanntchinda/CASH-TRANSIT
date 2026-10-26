# Saint Jacquet Distribution — Application Mobile (Android, iOS & PWA)

Application de transit logistique et de réservation de fret aérien et maritime au Cameroun (**Saint Jacquet Distribution**), configurée avec **Capacitor 7** pour être compilée nativement sur **Android** et **iOS**, ainsi qu'installable en **PWA**.

---

## Structure du projet

```text
CASH-TRANSIT/
├── www/                        # Sources Web embarquées dans l'application mobile
│   ├── index.html              # Application principale (adaptée Safe Area iOS/Android + pont Capacitor)
│   ├── manifest.webmanifest    # Manifeste PWA
│   ├── sw.js                   # Service Worker hors-ligne (mode Web/PWA)
│   └── assets/                 # Logo et icônes extraits (logo.jpg, icon-192, icon-512, maskable...)
├── android/                    # Projet natif Android Studio / Gradle (prêt à compiler en .apk / .aab)
├── ios/                        # Projet natif Xcode / CocoaPods (prêt à compiler sur macOS)
├── resources/                  # Ressources maîtresses HD (icônes 1024×1024 et splash 2732×2732)
├── scripts/
│   ├── generate-assets.sh      # Script de régénération des icônes & splash screens (Android/iOS/PWA)
│   └── serve.mjs               # Serveur local d'aperçu Web (port 8080)
├── .github/workflows/
│   └── build-mobile.yml        # Compilation automatique Android (.apk/.aab) & iOS (.ipa) sur GitHub Actions
├── capacitor.config.json       # Configuration Capacitor (ID: com.saintjacquet.distribution)
└── package.json                # Scripts et dépendances Capacitor
```

---

## Identifiants de l'application

- **Nom de l'application** : `Saint Jacquet Distribution`
- **Identifiant de paquet (Bundle ID / Application ID)** : `com.saintjacquet.distribution`
- **Compte administrateur par défaut** :
  - **Identifiant** : `admin`
  - **Mot de passe** : `Admin@2026`

---

## Option 1 : Compilation automatique via GitHub Actions (sans rien installer)

Un workflow CI/CD est prêt dans `.github/workflows/build-mobile.yml`. Dès que le code est poussé sur GitHub (ou lancé manuellement depuis l'onglet **Actions** → **Compilation Mobile (Android & iOS)** → **Run workflow**) :

1. **Job Android** : génère automatiquement l'artefact **`Saint-Jacquet-Distribution-Android`** contenant :
   - `Saint-Jacquet-Distribution-installable.apk` (APK signé Debug installable directement sur téléphone Android)
   - `Saint-Jacquet-Distribution-release-unsigned.apk` (APK Release à signer pour distribution)
   - `Saint-Jacquet-Distribution-release.aab` (Android App Bundle pour Google Play Store)
2. **Job iOS** : compile le projet Xcode sur macOS et génère l'artefact **`Saint-Jacquet-Distribution-iOS`** (`Saint-Jacquet-Distribution-unsigned.ipa`).

---

## Option 2 : Compiler localement sur votre ordinateur

### Prérequis communs
- **Node.js 20+**
- Installer les dépendances :
  ```bash
  npm install
  ```

### Compiler pour Android (`.apk` / `.aab`)
Prérequis : **Android Studio** (avec JDK 21 et Android SDK 35).

- **Via Android Studio (recommandé)** :
  ```bash
  npm run sync:android
  npm run open:android
  ```
  Puis dans Android Studio : menu **Build → Build Bundle(s) / APK(s) → Build APK(s)** (ou **Generate Signed Bundle / APK** pour le Play Store).

- **En ligne de commande** :
  ```bash
  npm run build:apk
  ```
  Le fichier APK généré se trouve dans :
  `android/app/build/outputs/apk/debug/app-debug.apk`

### Compiler pour iOS (sur Mac avec Xcode)
Prérequis : **macOS**, **Xcode 15+**, **CocoaPods** (`sudo gem install cocoapods` ou `brew install cocoapods`).

```bash
npm run sync:ios
npm run open:ios
```
Dans Xcode :
1. Sélectionnez la cible **App** → onglet **Signing & Capabilities**, puis choisissez votre **Team** Apple Developer.
2. Branchez votre iPhone ou choisissez **Any iOS Device (arm64)** puis cliquez sur **Product → Archive** (ou **Run ▶**).

---

## Aperçu Web local & régénération des icônes

- **Lancer l'aperçu dans le navigateur** :
  ```bash
  npm start
  ```
  Ouvrez `http://localhost:8080`.

- **Régénérer toutes les icônes et écrans de démarrage** (si vous remplacez `www/assets/logo.jpg`, nécessite ImageMagick `convert`) :
  ```bash
  npm run assets
  npm run sync
  ```
