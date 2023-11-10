#include <Arduino.h>
#line 1 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_noLoop.ino"
// COMPILER DIRECTIVES

#include <SPI.h>
#include <Ethernet3.h>
#include <ArduinoRS485.h> // ArduinoModbus depends on the ArduinoRS485 library
#include <ArduinoModbus.h>
#include <HX711.h>

// USEFUL REGISTERS
#define Rposact 0   // actual position
#define Rpostarg 8  // target position
#define Rhofs 36    // offset position after homing
#define Rcmdwr 59   // command register
#define Rvel 63     // traslation speed
#define Racc 67     // acceleration ramp
#define Rdec 70     // deceleration ramp
#define Rhmode 82   // home mode selection
#define Rstsflg 199 // status flags
#define Ralarm 227  // alarms flags

// HX711 pins
#define DT_PIN A0
#define SCK_PIN A1

//-------------------------------------------------

// USEFUL CONSTANT
const int32_t vel = 10;      // rps
const int32_t vel_tare = 0.1;      // rps
const uint32_t acc_ramp = 10    ; // no acceleration ramp

const float home_err = 0.05; // 5% error band to retrieve the no-force initial position

// VARIABLES
uint16_t sts = 0;     // status of the driver
float target = 0;     // target position [mm]
float tare_force = 0; // tare measured before taking any measurement
int32_t init_pos = 0; // value of the initial position

int8_t FULLSCALE = 1; // the fullscale of the loadcell
float min_pos = 0;    // minimal position in spacial axis
float max_pos = 0;    // maximal position in spacial axis
int num_pos = 0;      // # of spacial points

uint8_t pos_idx = 0; // index to navigate the pos_sorted array
float sum_p = 0;
float sum_m = 0;
float avg_thr = 5; // mm below which is done an average measure
uint8_t cnt = 4;   //

// FLAGS
bool mean_active = false;
bool ar_flag = false;

// HX711 object
HX711 loadcell;

// IP CONFIG
byte mac[] = {0xA8, 0x61, 0x0A, 0xAE, 0xBB, 0xA9};

IPAddress ip_null(0, 0, 0, 0);
IPAddress server(192, 168, 56, 1); // ip address of SMD1204

EthernetClient ethClient;
ModbusTCPClient modbusTCPClient(ethClient);

float t1 = 0;
float t2 = 0;
float t3 = 0;

// SETUP
#line 72 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_noLoop.ino"
void setup();
#line 159 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_noLoop.ino"
void loop();
#line 161 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_noLoop.ino"
void flushSerial();
#line 169 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_noLoop.ino"
void checkModbusConnection();
#line 3 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\HX711_Functions.ino"
float getForce();
#line 33 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\HX711_Functions.ino"
float getForce1(int x);
#line 43 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\HX711_Functions.ino"
float getForce3(int x);
#line 52 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\HX711_Functions.ino"
float getForce10(int x);
#line 61 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\HX711_Functions.ino"
float getForce50(int x);
#line 3 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
uint16_t disableDrive();
#line 10 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
uint16_t enableDrive();
#line 17 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
uint16_t abortDrive();
#line 24 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
uint16_t stop();
#line 31 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
uint16_t go();
#line 38 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
uint16_t gor();
#line 45 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
uint16_t home();
#line 53 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
void sendCommand(uint16_t cmd);
#line 65 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
void driverSetup();
#line 115 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
void homingRoutine();
#line 169 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
void measureRoutine();
#line 293 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
void getStatus();
#line 298 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
void printStatus();
#line 340 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
void printAlarms();
#line 381 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
void splitU32to16(uint32_t toSplit);
#line 387 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
void split32to16(int32_t toSplit);
#line 393 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
void awaitKeyPressed();
#line 405 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
void sendPosTarget(int32_t pos);
#line 414 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
int32_t mm2int(float pos_mm);
#line 419 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
int32_t getPosact();
#line 428 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
void printForce(uint8_t i, int32_t pos, float pos_mm, float force);
#line 442 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
int getAvgCnt(float val);
#line 72 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_noLoop.ino"
void setup()
{
    // Setting up Serial Port Communication
    Serial.begin(38400);
    while (!Serial)
    {
        ; // wait for serial port to connect. Needed for native USB port only
    }

    // read parameters from gui
    Serial.write("Ready to read!\n");
    while (Serial.readStringUntil("\n") != "Ready to write\n"){
    }

    // flushSerial();
    Serial.write("loadcell\n");
    FULLSCALE = Serial.parseInt();

    // flushSerial();
    Serial.write("min_pos\n");
    min_pos = Serial.parseFloat();

    // flushSerial();
    Serial.write("max_pos\n");
    max_pos = Serial.parseFloat();

    // flushSerial();
    Serial.write("num_pos\n");
    num_pos = Serial.parseInt();

    // flushSerial();
    Serial.write("media\n");
    mean_active = bool(Serial.parseInt());
    
    // flushSerial();
    Serial.write("a_r\n");
    ar_flag = bool(Serial.parseInt());
    Serial.println(ar_flag);

    flushSerial();

    // ----------------------------------------------

    // initialize loadcell
    loadcell.begin(DT_PIN, SCK_PIN);
    loadcell.set_gain((uint32_t)128, true);

    // ----------------------------------------------

    // Init IP communication
    Serial.write("Initializing...\n");
    // Ethernet.begin(mac, server);
    Ethernet.begin(mac, server);
    // start the Ethernet connection and the server:
    delay(500);
    Serial.write("Connecting\n");

    while (Ethernet.linkReport() == "NO LINK")
    {
        Serial.write("Ethernet cable is not connected.\n");
        delay(1000);
    }
    Serial.write("Cable connected!\n");
    while (Ethernet.localIP() == ip_null)
    {
        Serial.write("Invalid IP Adress obtained...\n");
        delay(1000);
    }
    Serial.println(Ethernet.localIP());

    // MODBUS CONNECTION
    checkModbusConnection();

    // DRIVER SETUP
    driverSetup();

    // HOMING ROUTINE
    homingRoutine();

    // MEASURE ROUTINE
    delay(500);
    measureRoutine();

    // FINISH MEASUREMENT
    Serial.write("Finished\n");
}

void loop() {}

void flushSerial()
{
    while (Serial.available() > 0)
    {
        Serial.read();
    }
}

void checkModbusConnection()
{
    String time = "time: ";
    t1 = millis();
    if (!modbusTCPClient.connected())
    {
        // client not connected, start the Modbus TCP client
        Serial.println("Attempting to connect to Modbus TCP server");

        if (!modbusTCPClient.begin(server, 502))
        {
            Serial.println("Modbus TCP Client failed to connect...");
        }
        else
        {
            Serial.println("Modbus TCP Client connected!");
        }
    }
    t2 = millis();
    // t2=millis();
    Serial.println(time + (t2 - t1));
}
#line 1 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\HX711_Functions.ino"


float getForce()
{
  float force = 0;
  while (!loadcell.is_ready())
  {
  }
  int val = loadcell.read_average(5);
  switch (FULLSCALE)
  {
  case 1:
    force = getForce1(val);
    break;
  case 3:
    force = getForce3(val);
    break;
  case 10:
    force = getForce10(val);
    break;
  case 50:
    force = getForce50(val);
    break;
  default:
    Serial.println("Error in retrieving the force...");
    break;
  }
  return force;
}

// insert poynomials coefficients computed for each load cell
// x is the number read from the loadcell
float getForce1(int x)
{
  // FIXME: insert the right ones
  float a = 2.35491e-08;
  float b = 0.0237357;
  float c = -0.442871;
  float force = a * x * x + b * x + c;
  return force;
}

float getForce3(int x)
{
  float a = 0;
  float b = 0;
  float c = 0;
  float force = a * x * x + b * x + c;
  return force;
}

float getForce10(int x)
{
  float a = 0;
  float b = 0;
  float c = 0;
  float force = a * x * x + b * x + c;
  return force;
}

float getForce50(int x)
{
  float a = 0;
  float b = 0;
  float c = 0;
  float force = a * x * x + b * x + c;
  return force;
}
#line 1 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
uint16_t splitted[2]; // utility array to split a 32 bit data into 2x16 bit data

uint16_t disableDrive()
{
  uint16_t cmd = 0;
  bitWrite(cmd, 0, 1);
  return cmd;
}

uint16_t enableDrive()
{
  uint16_t cmd = 0;
  bitWrite(cmd, 1, 1);
  return cmd;
}

uint16_t abortDrive()
{
  uint16_t cmd = 0;
  bitWrite(cmd, 2, 1);
  return cmd;
}

uint16_t stop()
{
  uint16_t cmd = 0;
  bitWrite(cmd, 3, 1);
  return cmd;
}

uint16_t go()
{
  uint16_t cmd = 0;
  bitWrite(cmd, 7, 1);
  return cmd;
}

uint16_t gor()
{
  uint16_t cmd = 0;
  bitWrite(cmd, 8, 1);
  return cmd;
}

uint16_t home()
{
  uint16_t cmd = 0;
  bitWrite(cmd, 9, 1);
  return cmd;
}

// function to send a command in the Rcmdwr register
void sendCommand(uint16_t cmd)
{
  if (modbusTCPClient.holdingRegisterWrite(Rcmdwr, cmd))
  {
    ; // do nothing since the message has been sent
  }
  else
  {
    Serial.write("\n\nCOMMAND NOT SENDED!\n");
  }
}

void driverSetup()
{
  // reset all alarms
  modbusTCPClient.holdingRegisterWrite(Ralarm, 0);
  // modbusTCPClient.holdingRegisterWrite(Rpostarg, int16_t(0));
  // modbusTCPClient.holdingRegisterWrite(Rpostarg + 1, int16_t(0));
  sendPosTarget((int32_t)0);

  // check status
  if (modbusTCPClient.holdingRegisterRead(Rstsflg) != -1)
  {
    sts = modbusTCPClient.holdingRegisterRead(Rstsflg);
  }

  // enable drive if disabled
  if (!bitRead(sts, 0))
    sendCommand(enableDrive());
  else
  {
    // DEVICE ENABLED - SETTINGS HERE
    // Home Method
    split32to16(mm2int(0));
    modbusTCPClient.holdingRegisterWrite(Rhofs, splitted[0]);
    modbusTCPClient.holdingRegisterWrite(Rhofs + 1, splitted[1]);
    // TODO: change homing method to -9
    // modbusTCPClient.holdingRegisterWrite(Rhmode, (int16_t)(-9)); // in battuta indietro
    modbusTCPClient.holdingRegisterWrite(Rhmode, int16_t(0)); // azzeramento sul posto

    // velocity setting - rps*100
    split32to16(vel * 100);
    if (modbusTCPClient.holdingRegisterWrite(Rvel, splitted[0]) && modbusTCPClient.holdingRegisterWrite(Rvel + 1, splitted[1]))
    {
      Serial.print("Velocita' massima settata a: ");
      Serial.print(vel);
      Serial.println(" rps");
    }

    // disable acceleration ramp
    splitU32to16(acc_ramp * 100);
    if (!(modbusTCPClient.holdingRegisterWrite(Racc, splitted[0]) && modbusTCPClient.holdingRegisterWrite(Racc + 1, splitted[1])))
    {
      Serial.write("Failed to disable acceleration ramp\n");
    }
    if (!(modbusTCPClient.holdingRegisterWrite(Rdec, splitted[0]) && modbusTCPClient.holdingRegisterWrite(Rdec + 1, splitted[1])))
    {
      Serial.write("Failed to disable deceleration ramp\n");
    }
  }
}

void homingRoutine()
{
  // seek the position in which the value of hx711 is equal to unclamped (in error band)
  sendCommand(home());

  Serial.write("Porre il centratore sulla cella...\n");
  // Serial.write("Premere enter\n");
  awaitKeyPressed();

  float tare = getForce();
  delay(1000);
  Serial.write("Clampare il centratore...\n");
  // Serial.write("Premere enter\n");
  awaitKeyPressed();

  float clamped = getForce();

  float err = fabs(clamped - tare);

  split32to16(vel_tare * 100);
  if (modbusTCPClient.holdingRegisterWrite(Rvel, splitted[0]) && modbusTCPClient.holdingRegisterWrite(Rvel + 1, splitted[1]))
  {}

  // assuming loadcell reads x<0 when extended and x>0 when compressed
  int32_t pos;
  if (err > 0)
    pos = -32;
  else
    pos = 32;

  split32to16(pos);
  if (!(modbusTCPClient.holdingRegisterWrite(Rpostarg, splitted[0]) && modbusTCPClient.holdingRegisterWrite(Rpostarg + 1, splitted[1])))
  {
    Serial.write("Errore nel settaggio posizione...\n");
  }

  while (err > fabs(home_err * tare))
  {
    sendCommand(gor());
    delay(100);
    clamped = getForce();
    err = fabs(clamped - tare);
  }

  tare_force = clamped;
  init_pos = getPosact();
  // Serial.write("Init pos: ");
  // Serial.println(init_pos);

  split32to16(vel * 100);
  if (modbusTCPClient.holdingRegisterWrite(Rvel, splitted[0]) && modbusTCPClient.holdingRegisterWrite(Rvel + 1, splitted[1]))
  {}
}

void measureRoutine()
{
  Serial.write("Measure Routine\n");
  // teniamo tutto in macchina
  // inizializziamo qua
  // una volta misurato inviamo tutto con la seriale fuck
  float pos[num_pos];
  flushSerial();
  Serial.write("send me\n");
  flushSerial();
  for (int i = 0; i < num_pos; i++)
  {
    pos[i] = Serial.parseFloat(SKIP_WHITESPACE);
  }

  // for (int i = 0; i < num_pos; i++)
  // {
  //   Serial.println(pos[i]);
  // }

  float sum_p = 0;
  float sum_m = 0;
  String msg = "val ";
  char buff[15];
  char num[10];

  Serial.write("Measuring\n");

  Serial.write("andata\n");
  for (int i = 0; i < num_pos; i = i + 2)
  {
    int cnt = getAvgCnt(pos[i]);
    checkModbusConnection();
    for (int j = 0; j < cnt; j++)
    {
      // positive movement
      sendPosTarget(init_pos + mm2int(pos[i]));
      sendCommand(go());
      getStatus();
      while (bitRead(sts, 3))
        getStatus();
      sum_p += getForce();
      Serial.write("check percent\n");

      // negative movement
      sendPosTarget(init_pos + mm2int(pos[i + 1]));
      sendCommand(go());
      getStatus();
      while (bitRead(sts, 3))
        getStatus();
      sum_m += getForce();
      Serial.write("check percent\n");
      
      // delay(100);

      sendPosTarget(init_pos);
      sendCommand(go());
      getStatus();
      while (bitRead(sts, 3))
        getStatus();
      delay(2000);
    }
    float meas_p = sum_p / cnt;
    float meas_m = sum_m / cnt;

    dtostrf(meas_p, 10, 6, num);
    Serial.println(msg + num);
    dtostrf(meas_m, 10, 6, num);
    Serial.println(msg + num);

    sum_p = 0;
    sum_m = 0;
  }

  if (ar_flag)
  {
    Serial.write("ritorno\n");
    for (int i = num_pos - 1; i >= 0; i = i - 2)
    {
      int cnt = getAvgCnt(pos[i]);
      checkModbusConnection();
      for (int j = 0; j < cnt; j++)
      {
        // positive movement
        sendPosTarget(init_pos + mm2int(pos[i - 1]));
        sendCommand(go());
        getStatus();
        while (bitRead(sts, 3))
          getStatus();
        sum_p += getForce();
        Serial.write("check percent\n");

        // delay(100);
        
        // negative movement
        sendPosTarget(init_pos + mm2int(pos[i]));
        sendCommand(go());
        getStatus();
        while (bitRead(sts, 3))
          getStatus();
        sum_m += getForce();
        Serial.write("check percent\n");

        sendPosTarget(init_pos);
        sendCommand(go());
        getStatus();
        while (bitRead(sts, 3))
          getStatus();
        delay(2000);
      }
      float meas_p = sum_p / cnt;
      float meas_m = sum_m / cnt;

      dtostrf(meas_p, 10, 6, num);
      Serial.println(msg + num);
      dtostrf(meas_m, 10, 6, num);
      Serial.println(msg + num);

      sum_p = 0;
      sum_m = 0;
    }
  }
}

void getStatus()
{
  sts = modbusTCPClient.holdingRegisterRead(Rstsflg);
}

void printStatus()
{
  if (modbusTCPClient.holdingRegisterRead(Rstsflg) != -1)
  {
    Serial.println("\n\t Status: ");
    uint16_t this_sts = modbusTCPClient.holdingRegisterRead(Rstsflg);
    if (bitRead(this_sts, 0))
      Serial.println("Azionamento abilitato");
    if (bitRead(this_sts, 1))
      Serial.println("Azionamento in allarme");
    if (bitRead(this_sts, 2))
      Serial.println("Quota motore sincronizzata");
    if (bitRead(this_sts, 3))
      Serial.println("Motore in movimento teorico");
    if (bitRead(this_sts, 4))
      Serial.println("Motore in accelerazione");
    if (bitRead(this_sts, 5))
      Serial.println("Motore a velocita' costante");
    if (bitRead(this_sts, 6))
      Serial.println("Motore in decelerazione");
    if (bitRead(this_sts, 7))
      Serial.println("Segnalazioni da registro Rstscllp");
    if (bitRead(this_sts, 8))
      Serial.println("Home terminato con errore");
    if (bitRead(this_sts, 9))
      Serial.println("Stato corrente: 1=CurON");
    if (bitRead(this_sts, 10))
      Serial.println("Motore in posizione");
    if (bitRead(this_sts, 11))
      Serial.println("Errore di inseguimento");
    if (bitRead(this_sts, 12))
      Serial.println("Motore mosso durante lo stato disable");
    if (bitRead(this_sts, 13))
      Serial.println("Verso rotazione antioraria");
    if (bitRead(this_sts, 14))
      Serial.println("Quota attuale fuori dai limiti software");
    if (bitRead(this_sts, 15))
      Serial.println("Home in corso");
    Serial.println("");
  }
}

void printAlarms()
{
  if (modbusTCPClient.holdingRegisterRead(Ralarm) != -1)
  {
    Serial.println("\n---------------");
    Serial.println("\t ALARMS: ");
    uint16_t alarm = modbusTCPClient.holdingRegisterRead(Ralarm);
    if (bitRead(alarm, 0))
      Serial.println("Overcurrent HW");
    if (bitRead(alarm, 1))
      Serial.println("Overcurrent SW");
    if (bitRead(alarm, 2))
      Serial.println("I2T");
    if (bitRead(alarm, 3))
      Serial.println("Errore di posizione");
    if (bitRead(alarm, 4))
      Serial.println("Errore di inseguimento");
    if (bitRead(alarm, 5))
      Serial.println("Overload digital output");
    if (bitRead(alarm, 6))
      Serial.println("Sovratemperatura");
    if (bitRead(alarm, 7))
      Serial.println("Sovratensione");
    if (bitRead(alarm, 8))
      Serial.println("Sottotensione");
    if (bitRead(alarm, 9))
      Serial.println("Errore fasatura encoder");
    if (bitRead(alarm, 10))
      Serial.println("Fase A motore disconessa");
    if (bitRead(alarm, 11))
      Serial.println("Fase B motore disconessa");
    if (bitRead(alarm, 12))
      Serial.println("Timeout Posizionamento");
    if (bitRead(alarm, 13))
      Serial.println("Homing Error");
    if (!alarm)
      Serial.println("No alarm");
    Serial.println("");
  }
}

void splitU32to16(uint32_t toSplit)
{
  splitted[0] = (uint16_t)toSplit;
  splitted[1] = (uint16_t)(toSplit >> 16);
}

void split32to16(int32_t toSplit)
{
  splitted[0] = (uint16_t)toSplit;
  splitted[1] = (uint16_t)(toSplit >> 16);
}

void awaitKeyPressed()
{
  while (Serial.available() > 0)
  {
    Serial.read();
  }
  while (Serial.available() == 0)
  {
    ;
  }
}

void sendPosTarget(int32_t pos)
{
  split32to16(pos);
  if (!(modbusTCPClient.holdingRegisterWrite(Rpostarg, splitted[0]) && modbusTCPClient.holdingRegisterWrite(Rpostarg + 1, splitted[1])))
  {
    Serial.write("Errore nella scrittura della posizione\n");
  }
}

int32_t mm2int(float pos_mm)
{
  return int32_t(pos_mm * 2048 / 5);
}

int32_t getPosact()
{
  int16_t lo = modbusTCPClient.holdingRegisterRead(Rposact);
  int16_t hi = modbusTCPClient.holdingRegisterRead(Rposact + 1);
  int32_t data = hi;
  data = (data << 16) | lo;
  return data;
}

void printForce(uint8_t i, int32_t pos, float pos_mm, float force)
{
  Serial.print("IDX: ");
  Serial.print(i);
  Serial.print(" Force at ");
  Serial.print(pos);
  Serial.print(" pos ");
  Serial.print(pos_mm);
  Serial.print(" mm is ");
  Serial.print(force);
  Serial.println(" N");
}

// TODO: cnt threshold function
int getAvgCnt(float val)
{
  float th1 = 1; // mm
  float th2 = 3; // mm
  float th3 = 5; // mm
  int cnt = 1;
  if (mean_active)
  {
    if (fabs(val) <= th3)
      cnt = 2;
    if (fabs(val) <= th2)
      cnt = 4;
    if (fabs(val) <= th1)
      cnt = 6;
  }
  return cnt;
}
