# Modèle Core ML — Ronflement

## Fichier attendu

`SnoreClassifier.mlmodel` (compilé en `.mlmodelc` dans le bundle)

## Entraînement avec Create ML (recommandé)

1. **Dataset** (WAV ou CAF, ~1–5 s par fichier) :
   ```
   SnoreDataset/
     snore/        # ronflements réels ou Freesound (voir attributions)
     background/   # chambre, ventilateur, silence ambiant
   ```
   Viser **≥ 50 fichiers par classe**, variété de micros et de volumes.

2. **Create ML** (macOS) → **Sound Classification**
   - Drag `SnoreDataset`
   - Classes : `snore`, `background`
   - Durée fenêtre : **1 second**
   - Entraîner → **Evaluate** → Export **SnoreClassifier.mlmodel**

3. Copier le fichier ici :
   `SleepLab/Resources/ML/SnoreClassifier.mlmodel`

4. Rebuild Xcode — le modèle est compilé automatiquement.

## Contrat technique (app iOS)

| Élément | Valeur |
|--------|--------|
| Sample rate pipeline | 22 050 Hz |
| Chunk | 1 s = 22 050 échantillons float32 |
| Seuil | confiance **snore ≥ 0,85** |
| Entrée modèle | `MLMultiArray` nom variable (souvent `waveform` ou `audioSamples`) |
| Sorties | `classLabel` + `classProbability` (ou `target` / `targetProbability`) |
| Stockage | `SnoreEvent` SwiftData — **pas d’audio** sauf opt-in Profil |

Si le `.mlmodel` est absent (pas de Mac / pas encore entraîné), l’app utilise un **repli heuristique** spectral (basses fréquences, exclusion toux) — seuil **0,80**. Pas besoin de Mac pour tester le ronflement.

## Script placeholder

```bash
cd SleepLab
pip install coremltools numpy scikit-learn
python3 Scripts/train_snore_classifier.py
```

Remplacez par un vrai modèle Create ML avant production.

## Confidentialité

- Inférence **on-device** (Neural Engine / CPU)
- Aucun envoi réseau
- Extraits audio uniquement si **Profil → Enregistrer des extraits audio la nuit** est activé
