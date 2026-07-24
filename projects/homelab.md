# Homelab / NAS media stack

| | |
|---|---|
| Live | [dashboard.voisintech.fr](https://dashboard.voisintech.fr) |
| Modèle open source | [enzo-jouet/homelab-media-stack](https://github.com/enzo-jouet/homelab-media-stack) |
| Stack | Docker · Cloudflare Tunnel · PWA · Navidrome · Immich · Node |

## Qu’est-ce que c’est

Un **dashboard média personnel** hébergé sur NAS, accessible en HTTPS depuis le téléphone :

- Musique (bibliothèque Navidrome + lecteur)
- Photos (Immich)
- Files d’attente / téléchargements
- Profils utilisateurs (style Netflix)
- PWA iOS (écran d’accueil)

Exposition publique via **Cloudflare Tunnel** (pas de ports ouverts sur la box).  
Jobs lourds optionnels délégués à un **worker PC** sur le LAN.

## Pourquoi c’est intéressant pour un recruteur

- Ops réel (Docker, volumes, tunnel, séparation UI / API / engines)
- Produit utilisé au quotidien, pas un compose “hello world”
- Complète le profil iOS / web avec une couche **infra / homelab**

## Lien avec le site

Le site métier reste **[voisintech.fr](https://www.voisintech.fr)** (devis, SEO, admin).  
Le dashboard est l’infra perso / média, sur le même domaine en sous-domaine.
