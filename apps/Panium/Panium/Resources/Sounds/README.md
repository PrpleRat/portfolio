# Sons WAV du handpan

Copie ici les fichiers depuis le projet Flutter :

```
c:\Users\jouet\Downloads\panium\sons_en_wave\*.wav
```

Vers :

```
Panium/Resources/Sounds/
```

## Convention de nommage

- `pos{position}_{note}_v{0|1|2}.wav`
- `v0` / `v1` / `v2` = niveaux de reverb

Exemple : `pos1_C_v0.wav`, `pos3_G_v1.wav`

## Liste complète (36 fichiers)

Voir `HandpanAudioEngine.soundNames` dans le code Swift, ou `SOUND_NAMES` dans le `MainActivity.kt` Android du projet Flutter.

Sans ces fichiers, l'app compile mais affiche **Sounds unavailable** au lancement.
