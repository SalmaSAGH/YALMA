# 🚀 YALMApp – Application mobile de réservation de trajets personnalisés

YALMApp est une application mobile développée avec Flutter, conçue pour faciliter la planification et la réservation de trajets urbains. Elle propose à l'utilisateur des itinéraires intelligents selon ses préférences de marche et de confort, tout en permettant une réservation automatique avec génération de ticket numérique.

---

## 📱 Fonctionnalités principales

- 🔐 **Inscription sécurisée avec coordonnées bancaires obligatoires**
- 🗺️ **Carte interactive** avec géolocalisation et recherche d'adresses via Google Maps
- 🧭 **Configuration de trajet** selon deux modes :
  - **Cheaper** : transports publics avec adaptation à la distance de marche maximale
  - **Faster** : trajet direct via taxi ou VTC
- 🛠️ **Paramétrage du profil** avec limite de marche personnalisable
- 🎫 **Réservation automatique** de moyens de transport avec génération de tickets numériques
- 📋 **Interface administrateur** pour vérifier les utilisateurs enregistrés

---

## 🧰 Technologies utilisées

- **Flutter (Dart)** – Framework UI principal
- **Google Maps SDK & Places API** – Cartographie, géolocalisation, recherche de lieux
- **Navigation SDK** – Calcul et affichage de trajets
- **SharedPreferences** – Stockage local des préférences et données utilisateur


---

## ⚙️ Installation et exécution

### Prérequis

- Flutter SDK installé
- Android Studio ou VS Code
- Clés API Google Maps activées dans `android/app/src/main/AndroidManifest.xml`

### Étapes

```bash
git clone https://github.com/SalmaSAGH/YALMA.git
cd transport_app
flutter pub get
flutter run

