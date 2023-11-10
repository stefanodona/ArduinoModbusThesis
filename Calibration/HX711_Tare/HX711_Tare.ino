#include <HX711.h>

#define DT_PIN A0
#define SCK_PIN A1

HX711 loadcell;
int num_meas = 10;

void setup()
{

    loadcell.begin(DT_PIN, SCK_PIN);
    loadcell.set_gain(128);

    Serial.begin(9600);

    while (!Serial)
    {
        ;
    }

    Serial.println("#1 Porre la cella in posizione orizzontale");
    Serial.println("Premere enter...");
    awaitKeyPressed();

    String msg = "val ";
    char num[15];
    for (int i = 0; i < num_meas; i++)
    {
        float meas = loadcell.read_average(10);
        dtostrf(meas, 10, 6, num);
        Serial.println(msg+num);
        delay(1000);
    }

    flushSerial();            
    Serial.println("#2 Porre la cella in posizione verticale appoggiata");
    Serial.println("Premere enter...");
    awaitKeyPressed();

    for (int i = 0; i < num_meas; i++)
    {
        float meas = loadcell.read_average(10);
        dtostrf(meas, 10, 6, num);
        Serial.println(msg+num);
        delay(1000);
    }

    flushSerial();            
    Serial.println("#3 Porre la cella in posizione verticale appoggiata gancio sopra");
    Serial.println("Premere enter...");
    awaitKeyPressed();

    for (int i = 0; i < num_meas; i++)
    {
        float meas = loadcell.read_average(10);
        dtostrf(meas, 10, 6, num);
        Serial.println(msg+num);
        delay(1000);
    }

    flushSerial();        
    Serial.println("#4 Porre la cella appesa senza gancio sotto");
    Serial.println("Premere enter...");
    awaitKeyPressed();

    for (int i = 0; i < num_meas; i++)
    {
        float meas = loadcell.read_average(10);
        dtostrf(meas, 10, 6, num);
        Serial.println(msg+num);
        delay(1000);
    }

    flushSerial();
    Serial.println("#5 Porre la cella appesa con gancio sotto");
    Serial.println("Premere enter...");
    awaitKeyPressed();

    for (int i = 0; i < num_meas; i++)
    {
        float meas = loadcell.read_average(10);
        dtostrf(meas, 10, 6, num);
        Serial.println(msg+num);
        delay(1000);
    }

    Serial.println("Finito");
}

void loop() {}

void flushSerial()
{
    while (Serial.available() > 0)
    {
        Serial.read();
    }
}
void awaitKeyPressed()
{
    flushSerial();
    while (Serial.available() == 0)
    {
        ;
    }
}