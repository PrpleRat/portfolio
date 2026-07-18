# Gesture Photo Studio (Standalone Windows)

Version sans installation: **double-clique directement `index.html`**.

## Démarrage ultra simple

1. Ouvre le dossier `gesture-photo-studio`
2. Double-clique `index.html`
3. Clique `Activer caméra` (optionnel) et importe une image

## Important

- Aucun `npm install` requis pour cette version.
- Fonctionne en local via `file://` sur Windows.

## Permissions webcam
- l’app demande l’autorisation caméra dès le démarrage du contrôle gestuel
- bouton pause caméra
- bouton mode démo sans webcam

## Fonctionnalités MVP+
- import image
- zoom/pan/rotation
- luminosité/contraste/saturation/exposition/température/netteté
- undo/redo (30 états)
- reset
- HUD geste + confidence bar
- onboarding express + cheat sheet
- fallback souris/clavier

## Tests

```bash
npm test
```

## Robustesse terrain (protocole)
Tester dans:
1. faible lumière
2. fond visuel chargé
3. main partiellement hors cadre

Mesurer:
- FPS moyen
- latence geste -> action
- faux positifs / minute

## Limites connues
- moteur gestuel en mode démo simulé (sans modèle IA réel MediaPipe)
- export PNG/JPEG qualité réglable à compléter
- crop rectangle à finaliser (roadmap V2)

## Roadmap V2
- multi-main
- presets IA
- raccourcis vocaux
- crop avancé + masque
