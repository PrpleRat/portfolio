# Enzo Jouet — Portfolio développeur

**iOS · Mobile · Full-stack** — Toulouse, France

Apps natives Swift/SwiftUI, React Native (Expo), et produits web en production.

| | |
|---|---|
| **Email** | [jouet.enzo@gmail.com](mailto:jouet.enzo@gmail.com) |
| **LinkedIn** | [Enzo Jouet](https://www.linkedin.com/in/enzo-jouet-bb187a222) |
| **Téléphone** | [07 68 20 98 54](tel:+33768209854) |
| **GitHub** | [github.com/enzo-jouet](https://github.com/enzo-jouet) |
| **Site** | [voisintech.fr](https://www.voisintech.fr) |
| **Dashboard NAS** | [dashboard.voisintech.fr](https://dashboard.voisintech.fr) |

---

## Stack

```text
Mobile natif     Swift · SwiftUI · SwiftData · HealthKit · CoreMotion · AVFoundation · Widgets · Live Activities
Cross-platform   React Native · Expo · Expo Router · TypeScript
Web              Next.js · React · Prisma · TypeScript
CI / Release     GitHub Actions · XcodeGen · TestFlight (pipeline multi-apps partagé)
Homelab / Ops    Docker · Cloudflare Tunnel · NAS · PWA media stack
```

---

## Code source dans ce repo

Le dossier [`apps/`](./apps/) contient le code **sanitisé** (pas de clés API, pas de certificats, pas de Team ID Apple).

| Dossier | Description |
|---------|-------------|
| [`apps/BeatDeal`](./apps/BeatDeal) | Contrats de licence beats — SwiftUI, PDF offline |
| [`apps/BeatBill`](./apps/BeatBill) | Factures producteurs — Expo / React Native |
| [`apps/DropDay`](./apps/DropDay) | Planification de sorties musicales — Expo |
| [`apps/SplitPad`](./apps/SplitPad) | Split sheets studio — Expo |
| [`apps/SleepLab`](./apps/SleepLab) | Noctavia — suivi sommeil (HealthKit, capteurs) |
| [`apps/TrajOc`](./apps/TrajOc) | Trajets Occitanie (transports, vélo, carte) |
| [`apps/RAS`](./apps/RAS) | Fusée de détresse — dead man’s switch |
| [`apps/CarenceScan`](./apps/CarenceScan) | Bilan carences → PDF médecin, 100 % local |
| [`apps/Panium`](./apps/Panium) | Handpan tactile — audio SwiftUI |
| [`apps/PhotoSpaceCleaner`](./apps/PhotoSpaceCleaner) | Tri / nettoyage photothèque — Expo |
| [`apps/gesture-photo-studio`](./apps/gesture-photo-studio) | Édition photo + gestes webcam (web) |
| [`apps/Arduino`](./apps/Arduino) | Liaison radio NRF24L01 (émetteur / récepteur) |

Fiches détaillées : [`projects/`](./projects/)

---

## En production (live)

| URL | Rôle |
|-----|------|
| **[www.voisintech.fr](https://www.voisintech.fr)** | Site vitrine + devis + admin (Next.js) |
| **[dashboard.voisintech.fr](https://dashboard.voisintech.fr)** | Homelab / NAS — PWA média (musique, photos, files) via Cloudflare Tunnel |
| **[voisintech.fr/pro](https://www.voisintech.fr/pro)** | Espace Pro + suite iOS beta |

---

## Open source (toolkits)

| Repo | Description |
|------|-------------|
| **[ios-testflight-ci](https://github.com/enzo-jouet/ios-testflight-ci)** | CI TestFlight **sans Mac** (XcodeGen / Expo → GitHub Actions) |
| **[homelab-media-stack](https://github.com/enzo-jouet/homelab-media-stack)** | Modèle NAS : Docker + tunnel + PWA média + worker LAN |

---

## Suite pro (beta) — pas de code ici

La suite d’apps métier pour micro-entrepreneurs (agenda, facturation, compta, CRM) est présentée sur l’espace Pro du site — **beta** :

→ **[voisintech.fr/pro](https://www.voisintech.fr/pro)**  
→ **[voisintech.fr/train-suite](https://www.voisintech.fr/train-suite)**

Le code source de cette suite et du site web ne sont pas inclus dans ce portfolio.

---

## Homelab / NAS

Serveur maison (NAS) exposé en HTTPS sur **dashboard.voisintech.fr** :

- PWA installable (iOS) — profils type Netflix
- Musique (Navidrome), photos (Immich), files d’attente téléchargements
- Tunnel Cloudflare (pas d’ouverture de ports routeur)
- Worker PC optionnel pour les jobs lourds (CPU offload)

Modèle open source (sans secrets) : **[homelab-media-stack](https://github.com/enzo-jouet/homelab-media-stack)** · fiche [`projects/homelab.md`](./projects/homelab.md)

---

## Pipeline CI / build iOS partagé

Plusieurs apps iOS partagent la **même architecture de release** :

- génération de projet Xcode (`XcodeGen` / `expo prebuild`) en CI
- build + archive sur runners `macos`
- upload TestFlight via App Store Connect API
- secrets injectés uniquement via **GitHub Secrets** (jamais commités)

Toolkit public : **[ios-testflight-ci](https://github.com/enzo-jouet/ios-testflight-ci)** · détail : [`docs/ci-partage.md`](./docs/ci-partage.md)

---

## Ce que je cherche

Poste **développeur iOS**, **mobile** ou **full-stack TypeScript** — produit qui ship, ownership, qualité.

---

## Contact

**Enzo Jouet** · Toulouse  
[jouet.enzo@gmail.com](mailto:jouet.enzo@gmail.com) · [07 68 20 98 54](tel:+33768209854) · [LinkedIn](https://www.linkedin.com/in/enzo-jouet-bb187a222)
