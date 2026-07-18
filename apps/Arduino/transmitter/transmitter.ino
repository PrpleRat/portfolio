/*
 * Emetteur NRF24L01 — carte ATmega328P avec radio integree (type RF-Nano)
 *
 * Envoie "TEST-OK #N" toutes les 2 secondes.
 * Apres televersement : alimenter la carte sans PC (USB power bank, etc.)
 *
 * Bibliotheque : RF24 (nRF24) via le gestionnaire Arduino IDE
 */

#include <SPI.h>
#include <RF24.h>

// --- Broches radio integree (choisir UNE variante) ---

// Variante A — RF-Nano classique (Keywish, la plus repandue)
#define RF24_CE_PIN  10
#define RF24_CSN_PIN 9

// Variante B — certaines cartes V3 recentes (emakefun) : decommenter et commenter A
// #define RF24_CE_PIN  7
// #define RF24_CSN_PIN 8

// Adresse commune avec le recepteur (5 octets identiques)
const uint8_t RADIO_ADDRESS[6] = "BOS01";

const uint32_t SEND_INTERVAL_MS = 2000;

RF24 radio(RF24_CE_PIN, RF24_CSN_PIN);

uint32_t lastSendMs = 0;
uint16_t messageCount = 0;

bool initRadio() {
  if (!radio.begin()) {
    return false;
  }

  radio.setPALevel(RF24_PA_LOW);       // PA_LOW en test proche ; PA_HIGH si distance
  radio.setDataRate(RF24_250KBPS);     // Plus robuste que 1 Mbps en interieur
  radio.setChannel(76);                // Canal libre (0-125), identique au recepteur
  radio.setAutoAck(true);
  radio.setRetries(5, 15);
  radio.openWritingPipe(RADIO_ADDRESS);
  radio.stopListening();

  return true;
}

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  if (!initRadio()) {
    // Clignotement rapide = erreur init (reste sur USB pour debug)
    while (true) {
      digitalWrite(LED_BUILTIN, HIGH);
      delay(100);
      digitalWrite(LED_BUILTIN, LOW);
      delay(100);
    }
  }

  // Un flash = pret
  digitalWrite(LED_BUILTIN, HIGH);
  delay(200);
  digitalWrite(LED_BUILTIN, LOW);

  lastSendMs = millis();
}

void loop() {
  const uint32_t now = millis();

  if (now - lastSendMs < SEND_INTERVAL_MS) {
    return;
  }
  lastSendMs = now;

  messageCount++;

  char payload[32];
  snprintf(payload, sizeof(payload), "TEST-OK #%u", messageCount);

  const bool sent = radio.write(payload, strlen(payload) + 1);

  if (sent) {
    digitalWrite(LED_BUILTIN, HIGH);
    delay(30);
    digitalWrite(LED_BUILTIN, LOW);
  } else {
    // Double flash = echec envoi
    for (uint8_t i = 0; i < 2; i++) {
      digitalWrite(LED_BUILTIN, HIGH);
      delay(80);
      digitalWrite(LED_BUILTIN, LOW);
      delay(80);
    }
  }
}
