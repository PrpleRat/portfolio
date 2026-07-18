# Photo Space Cleaner

App Expo (Expo Go) pour **trier et supprimer** photos & vidéos sur iPhone, avec affichage de la taille et mode swipe façon « photo cleaner ».

## Lancer en 30 secondes

1. Installe **Expo Go** sur ton iPhone ([App Store](https://apps.apple.com/app/expo-go/id982107779))
2. Sur ton PC, dans ce dossier :

```bash
cd PhotoSpaceCleaner
npm install
npm start
```

3. Scanne le **QR code** avec l'appareil photo de l'iPhone (même Wi‑Fi que le PC)
4. Autorise l'**accès complet à la photothèque** quand iOS demande

## Fonctions

| Fonction | Description |
|----------|-------------|
| **Dashboard** | Espace libre sur l'iPhone, nombre de photos/vidéos |
| **Swipe** | Gauche = supprimer, droite = garder |
| **Filtres** | Tout, captures d'écran, vidéos, Live Photos |
| **Plus lourds** | Liste triée par taille |
| **Corbeille** | Validation avant suppression définitive |

## Limites iOS (important)

Apple **n'autorise pas** une app tierce à :

- parcourir les fichiers internes (WhatsApp, Mail, cache Safari, etc.)
- vider le cache système
- scanner tout le stockage comme le fait Réglages → Stockage

Cette app cible ce qui **libère vraiment de la place** : la **photothèque** (souvent la plus grosse part du stockage). Voir l'écran « Fichiers iPhone » dans l'app pour les astuces manuelles.

## iCloud

Les médias marqués **iCloud** ne sont pas tous stockés localement. La taille peut être **estimée** (symbole ≈). La suppression retire l'élément de ta bibliothèque (souvent aussi d'iCloud si synchronisé).

## Stack

- Expo SDK 56 + Expo Router
- `expo-media-library` (lecture + suppression)
- `react-native-gesture-handler` + `reanimated` (swipe)
- `expo-file-system` (stockage disque + taille fichiers locaux)

## Build standalone (optionnel)

Pour une app hors Expo Go (permissions complètes, icône perso) :

```bash
npx eas build --platform ios
```

Compte Apple Developer requis pour installer sur ton iPhone sans Expo Go.
