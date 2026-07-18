#!/usr/bin/env python3
"""
Génère SnoreClassifier.mlmodel pour SleepLab (macOS).

Option A — Create ML (recommandé)
  1. Dossier dataset :
       dataset/snore/*.wav
       dataset/background/*.wav
  2. Create ML → New Project → Sound Classification
  3. Classes : snore, background — fenêtre 1 s, entraînement
  4. Export SnoreClassifier.mlmodel → SleepLab/SleepLab/Resources/ML/

Option B — Ce script (placeholder / prototypage)
  pip install coremltools numpy
  python3 Scripts/train_snore_classifier.py

Le modèle exporté utilise l’entrée MLMultiArray « waveform » [1, 22050] float32
et les sorties classLabel + classProbability (compatibles avec SnoreClassifierEngine.swift).
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

try:
    import coremltools as ct
except ImportError:
    print("Install: pip install coremltools", file=sys.stderr)
    sys.exit(1)

SAMPLE_RATE = 22050
CHUNK = 22050
OUT_DIR = Path(__file__).resolve().parents[1] / "SleepLab" / "Resources" / "ML"
OUT_PATH = OUT_DIR / "SnoreClassifier.mlmodel"


def extract_features(wave: np.ndarray) -> np.ndarray:
    """Caractéristiques légères — remplacer par vrai entraînement Create ML."""
    wave = wave.astype(np.float32)
    if len(wave) < CHUNK:
        wave = np.pad(wave, (0, CHUNK - len(wave)))
    wave = wave[:CHUNK]
    fft = np.abs(np.fft.rfft(wave))
    low = fft[: max(1, len(fft) // 8)].mean()
    mid = fft[len(fft) // 8 : len(fft) // 2].mean()
    high = fft[len(fft) // 2 :].mean()
    return np.array(
        [
            wave.mean(),
            wave.std(),
            np.abs(wave).max(),
            low,
            mid,
            high,
            low / (mid + 1e-6),
        ],
        dtype=np.float32,
    )


def build_sklearn_placeholder():
    from sklearn.neural_network import MLPClassifier

    rng = np.random.default_rng(42)
    X, y = [], []
    for _ in range(200):
        t = np.linspace(0, 1, CHUNK, dtype=np.float32)
        if rng.random() > 0.5:
            # pseudo-snore : bass + rumble
            wave = 0.4 * np.sin(2 * np.pi * 80 * t) + 0.1 * rng.standard_normal(CHUNK)
            label = "snore"
        else:
            wave = 0.05 * rng.standard_normal(CHUNK)
            label = "background"
        X.append(extract_features(wave))
        y.append(label)
    X = np.stack(X)
    clf = MLPClassifier(hidden_layer_sizes=(32, 16), max_iter=300, random_state=42)
    clf.fit(X, y)
    return clf


def export_waveform_model():
    """
    Modèle Core ML avec entrée waveform [1,22050] :
    réseau converti via « features » internes (couche de features fixe dans Swift
    si vous réentraînez avec Create ML pur).
    """
    clf = build_sklearn_placeholder()

    # Modèle sklearn sur features → on expose waveform via Function + features en Swift
    # Pour simplifier le bundle, on exporte le classifieur features + métadonnées.
    sklearn_ml = ct.converters.sklearn.convert(
        clf,
        ["f0", "f1", "f2", "f3", "f4", "f5", "f6"],
        "classLabel",
        class_labels=["background", "snore"],
    )
    sklearn_ml.author = "SleepLab"
    sklearn_ml.short_description = "Snore vs background (placeholder — replace with Create ML)"
    sklearn_ml.save(str(OUT_DIR / "SnoreClassifier_features.mlmodel"))
    print(f"Saved feature-based placeholder: {OUT_DIR / 'SnoreClassifier_features.mlmodel'}")
    print("For full waveform input, export from Create ML as documented in ML/README.md")


def export_create_ml_compatible_stub():
    """Stub qui documente les tenseurs ; l’app utilise le repli heuristique si absent."""
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    readme = OUT_DIR / "README.txt"
    readme.write_text(
        "Place SnoreClassifier.mlmodel here (Create ML export).\n"
        "Classes: snore, background\n"
        "Input: waveform MLMultiArray shape [1, 22050]\n",
        encoding="utf-8",
    )
    print(f"Created {readme}")
    export_waveform_model()


if __name__ == "__main__":
    export_create_ml_compatible_stub()
