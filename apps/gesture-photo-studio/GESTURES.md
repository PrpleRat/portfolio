# Geste -> Action

| Geste | Description biomécanique | Action | Seuils | Anti faux positifs |
|---|---|---|---|---|
| Index seul | index tendu | curseur virtuel | lissage alpha 0.25 | vitesse max et smoothing |
| Dwell click | index immobile sur cible | clic | 700ms (600-800 configurable) | distance < 1% écran |
| Air tap | micro flexion index | clic rapide | 120-250ms | debounce 350ms |
| Pouce+Index | pinch court | zoom + pan | pinch < 0.06 | hysteresis 120ms |
| Pouce+Majeur | pinch moyen | rotation | pinch < 0.065 | lock outil 150ms |
| Pouce+Annulaire | pinch annulaire | luminosité/contraste/saturation | pinch < 0.07 | zone morte +-0.006 |
| Main ouverte | doigts écartés 1s | reset outil | spread > 0.30 | maintien 1s |
| Poing | main fermée 1s | lock/unlock gestes | spread < 0.15 | cooldown 1s |

## Gaucher / droitier
Calibration au démarrage: main dominante + sensibilité.
