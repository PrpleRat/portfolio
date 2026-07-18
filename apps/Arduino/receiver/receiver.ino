/*
 * Recepteur NRF24L01 — Arduino Uno + module NRF24L01 externe
 *
 * Affiche les messages recus sur le Moniteur serie (115200 baud).
 *
 * Bibliotheque : RF24 (nRF24) via le gestionnaire Arduino IDE
 */

#include <SPI.h>
#include <RF24.h>

// --- Broches module externe sur Uno (variante standard) ---
#define RF24_CE_PIN  9
#define RF24_CSN_PIN 10

// Variante alternative si la standard ne marche pas :
// #define RF24_CE_PIN  4
// #define RF24_CSN_PIN 7

// Adresse commune avec l'emetteur (5 octets identiques)
const uint8_t RADIO_ADDRESS[6] = "BOS01";

RF24 radio(RF24_CE_PIN, RF24_CSN_PIN);

char rxBuffer[32];

bool initRadio() {
  if (!radio.begin()) {
    return false;
  }

  radio.setPALevel(RF24_PA_LOW);
  radio.setDataRate(RF24_250KBPS);
  radio.setChannel(76);
  radio.setAutoAck(true);
  radio.setRetries(5, 15);
  radio.openReadingPipe(1, RADIO_ADDRESS);
  radio.startListening();

  return true;
}

void setup() {
  Serial.begin(115200);
  while (!Serial && millis() < 3000) {
    // Attendre l'ouverture du moniteur serie (Leonardo/Micro ; inoffensif sur Uno)
  }

  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  Serial.println();
  Serial.println(F("================================="));
  Serial.println(F("  NRF24L01 — Recepteur de test"));
  Serial.println(F("================================="));

  if (!initRadio()) {
    Serial.println(F("[ERREUR] ECHEC init radio NRF24L01."));
    Serial.println(F("Verifie le cablage (3.3V!) et les broches CE/CSN."));
    while (true) {
      digitalWrite(LED_BUILTIN, HIGH);
      delay(200);
      digitalWrite(LED_BUILTIN, LOW);
      delay(200);
    }
  }

  Serial.println(F("[NRF24 RX] Radio initialisee."));
  Serial.print(F("  CE="));
  Serial.print(RF24_CE_PIN);
  Serial.print(F("  CSN="));
  Serial.println(RF24_CSN_PIN);
  Serial.println(F("[NRF24 RX] En attente de messages..."));
  Serial.println();
}

void loop() {
  if (!radio.available()) {
    return;
  }

  const uint8_t len = radio.getDynamicPayloadSize();
  if (len == 0 || len >= sizeof(rxBuffer)) {
    radio.flush_rx();
    return;
  }

  memset(rxBuffer, 0, sizeof(rxBuffer));
  radio.read(rxBuffer, len);

  static uint32_t receiveCount = 0;
  receiveCount++;

  Serial.print(F(">>> Message recu | #"));
  Serial.print(receiveCount);
  Serial.print(F(" | \""));
  Serial.print(rxBuffer);
  Serial.println(F("\""));

  digitalWrite(LED_BUILTIN, HIGH);
  delay(50);
  digitalWrite(LED_BUILTIN, LOW);
}
