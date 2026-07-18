# Test radio Arduino — NRF24L01 (2,4 GHz)

Projet minimal pour vérifier la liaison sans fil entre :

| Rôle | Matériel |
|------|----------|
| **Émetteur** | Petite carte ATmega328P intégrée NRF24L01 (type RF-Nano / Nano V3 + radio embarquée) — alimentation autonome |
| **Récepteur** | Arduino Uno + module NRF24L01 externe — branchée au PC (Serial Monitor) |

Les modules **CC1101 (433 MHz)** sont pour une autre étape ; ce dossier ne couvre que le **NRF24L01**.

---

## Prérequis logiciels

1. [Arduino IDE](https://www.arduino.cc/en/software) (2.x recommandé)
2. Bibliothèque **RF24** : *Outils → Gérer les bibliothèques…* → chercher `RF24` (auteur **nRF24**) → Installer
3. Driver **CH340** si la petite carte n’est pas reconnue en USB (souvent le cas sur les clones Nano)

---

## Câblage — Arduino Uno + module NRF24L01 externe

| NRF24L01 | Arduino Uno |
|----------|-------------|
| VCC | **3,3 V** (pas 5 V) |
| GND | GND |
| CE | D9 |
| CSN | D10 |
| SCK | D13 |
| MOSI | D11 |
| MISO | D12 |

> Si ça ne communique pas, essaie la variante documentée sur certaines cartes RF-Nano : CE → D4, CSN → D7 (modifier `RF24_CE_PIN` / `RF24_CSN_PIN` dans `receiver/receiver.ino`).

**Important :** le NRF24L01 est en **3,3 V**. Sur breadboard, un régulateur 3,3 V ou un adaptateur NRF24 dédié évite les soucis. Ajouter un condensateur 10–100 µF entre VCC et GND du module aide la stabilité.

---

## Câblage — Petite carte (radio intégrée)

Aucun câblage radio : le NRF24L01 est déjà soudé sur la carte.

Broches SPI internes (variante la plus courante — Keywish / RF-Nano classique) :

| Signal | Broche |
|--------|--------|
| CE | D10 |
| CSN | D9 |
| MOSI / MISO / SCK | D11 / D12 / D13 |

Certaines cartes **V3 récentes** (ex. emakefun) utilisent **CE = D7** et **CSN = D8**. Si l’émetteur ne répond pas, change les defines en haut de `transmitter/transmitter.ino`.

Alimentation autonome (après programmation) :

- **VIN** ou **USB** : 5 V (batterie USB power bank, pack LiPo + step-up, etc.)
- Consommation typique : ~15–30 mA en émission périodique

---

## Installation des sketches

### 1. Récepteur (Arduino Uno)

1. Ouvre `receiver/receiver.ino`
2. *Outils → Carte* : **Arduino Uno**
3. *Outils → Port* : le port COM de l’Uno
4. Téléverse
5. *Outils → Moniteur série* : **115200 baud**

Tu dois voir :

```text
[NRF24 RX] Pret. En attente de messages...
```

### 2. Émetteur (petite carte)

1. Ouvre `transmitter/transmitter.ino`
2. *Outils → Carte* : **Arduino Nano**
3. *Outils → Processeur* : **ATmega328P** (ou **Old Bootloader** si erreur au téléversement)
4. Branche la carte en USB, choisis le bon port, téléverse
5. Débranche l’USB, alimente la carte (batterie / power bank)

L’émetteur envoie un message toutes les **2 secondes**.

### 3. Vérification

Sur le Moniteur série de l’Uno, tu dois voir défiler :

```text
>>> Message recu | compteur=1 | "TEST-OK #1"
```

La LED intégrée (D13) clignote à chaque message reçu.

---

## Dépannage rapide

| Symptôme | Piste |
|----------|-------|
| `ECHEC init radio` au démarrage | Mauvais câblage, alimentation 5 V sur le module, broches CE/CSN incorrectes |
| Init OK mais aucun message | Émetteur pas alimenté, mauvaise variante de broches sur la petite carte, distance trop grande (rapproche les cartes à 1 m) |
| Caractères illisibles sur le Serial | Vitesse du moniteur ≠ 115200 |
| Téléversement échoue sur la Nano | Essaie *ATmega328P (Old Bootloader)*, installe le driver CH340 |

Test de base : place les deux cartes côte à côte (< 1 m), sans obstacle métallique.

---

## Structure du dossier

```text
Arduino/
├── README.md
├── transmitter/
│   └── transmitter.ino    # Émetteur — carte NRF intégrée
└── receiver/
    └── receiver.ino       # Récepteur — Uno + module externe
```

---

## Suite possible — CC1101 (433 MHz)

Quand le test NRF24 fonctionne, on pourra ajouter un dossier `cc1101-test/` avec la bibliothèque **SmartRC-CC1101-Driver-Lib** pour tester les modules 433 MHz.
