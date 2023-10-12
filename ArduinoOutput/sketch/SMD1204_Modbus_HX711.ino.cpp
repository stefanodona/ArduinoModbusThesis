#include <Arduino.h>
#line 1 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Modbus_HX711.ino"
// COMPILER DIRECTIVES

#include <SPI.h>
#include <Ethernet3.h>
#include <ArduinoRS485.h> // ArduinoModbus depends on the ArduinoRS485 library
#include <ArduinoModbus.h>
#include <HX711.h>

// USEFUL REGISTERS
#define Rposact 0   // actual position
#define Rpostarg 8  // target position
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
const int8_t SETUP_DRIVE = 0;   // program phases
const int8_t PARAMETERS = 1;
const int8_t HOMING = 2;
const int8_t MEASUREMENT = 3;
const int8_t END_PROGRAM = 4;

const int32_t vel = 10;       // rps
const uint32_t acc_ramp = 0; // no acceleration ramp

const float home_err = 0.005; // 0.5% error band to retrieve the no-force initial position

// VARIABLES
uint16_t sts = 0;           // status of the driver
int8_t PHASE = SETUP_DRIVE; // which phase of the program we're in (HOMING, MEAS, ...)
int8_t FULLSCALE = 1;       // the fullscale of the loadcell
float target = 0;           // target position [mm]
float tare_force = 0;       // tare measured before taking any measurement
int32_t init_pos = 0;       // value of the initial position 
float min_pos = 0;          // minimal position in spacial axis
float max_pos = 0;          // maximal position in spacial axis
int num_pos = 0;            // # of spacial points
float *meas_pos;            // array with displacement axis (spacial mesh)
float *pos_sorted;          // array with meas_pos entries sorted by ascending absolute value 
float *meas_force;          // array where measured forces are stored in
uint8_t pos_idx = 0;        // index to navigate the pos_sorted array

// FLAGS
bool mean_active = false;

// HX711 object
HX711 loadcell;

// IP CONFIG
byte mac[] = {0xA8, 0x61, 0x0A, 0xAE, 0xBB, 0xA9};

IPAddress ip_null(0, 0, 0, 0);
IPAddress server(192, 168, 56, 1); // ip address of SMD1204

EthernetClient ethClient;
ModbusTCPClient modbusTCPClient(ethClient);

// SETUP
#line 69 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Modbus_HX711.ino"
void setup();
#line 106 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Modbus_HX711.ino"
void loop();
#line 1 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\HX711_management.ino"
void selectLoadcell();
#line 35 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\HX711_management.ino"
float getForce();
#line 65 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\HX711_management.ino"
float getForce1(int x);
#line 75 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\HX711_management.ino"
float getForce3(int x);
#line 84 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\HX711_management.ino"
float getForce10(int x);
#line 93 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\HX711_management.ino"
float getForce50(int x);
#line 3 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
uint16_t disableDrive();
#line 10 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
uint16_t enableDrive();
#line 17 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
uint16_t abortDrive();
#line 24 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
uint16_t stop();
#line 31 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
uint16_t go();
#line 38 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
uint16_t gor();
#line 45 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
uint16_t home();
#line 53 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
void sendCommand(uint16_t cmd);
#line 65 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
void driverSetup();
#line 114 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
void parametersSettings();
#line 166 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
void homingRoutine();
#line 225 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
void measureRoutine();
#line 274 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
void getStatus();
#line 279 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
void printStatus();
#line 321 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
void printAlarms();
#line 362 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
void splitU32to16(uint32_t toSplit);
#line 368 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
void split32to16(int32_t toSplit);
#line 374 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
void awaitKeyPressed();
#line 386 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
void sendPosTarget(int32_t pos);
#line 395 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
int32_t mm2int(float pos_mm);
#line 400 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
int32_t getPosact();
#line 409 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
void populatePosArray();
#line 422 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
void sortArray();
#line 69 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Modbus_HX711.ino"
void setup()
{
  // Setting up Serial Port Communication
  Serial.begin(9600);
  while (!Serial)
  {
    ; // wait for serial port to connect. Needed for native USB port only
  }

  // initialize loadcell
  loadcell.begin(DT_PIN, SCK_PIN);
  loadcell.set_gain((uint32_t)128, true);

  // ----------------------------------------------

  // Init IP communication
  Serial.println("\n\nInitializing...");
  Ethernet.begin(mac, server);
  // start the Ethernet connection and the server:
  delay(1000);
  Serial.println("Connecting...");

  while (Ethernet.linkReport() == "NO LINK")
  {
    Serial.println("Ethernet cable is not connected.");
    delay(1000);
  }
  Serial.println("Cable connected!");
  while (Ethernet.localIP() == ip_null)
  {
    Serial.println("Invalid IP Adress obtained...");
    delay(1000);
  }
  Serial.println(Ethernet.localIP());

}

void loop()
{
  // Check connection of modbus
  if (!modbusTCPClient.connected())
  {
    // client not connected, start the Modbus TCP client
    Serial.println("Attempting to connect to Modbus TCP server");

    if (!modbusTCPClient.begin(server, 502))
    {
      Serial.println("Modbus TCP Client failed to connect...");
      delay(2000);
    }
    else
    {
      Serial.println("Modbus TCP Client connected!");
    }
  }
  else
  {
    // CLIENT CONNECTED
    switch (PHASE)
    {
    case SETUP_DRIVE:
      Serial.println("SETUP DRIVE");
      driverSetup();
      selectLoadcell();
      break;
    case PARAMETERS:
      Serial.println("PARAMETERS");
      parametersSettings();
      break;
    case HOMING:
      Serial.println("HOMING");
      homingRoutine();
      break;
    case MEASUREMENT:
      // Serial.println("MEASUREMENT");
      measureRoutine();
      break;
    case END_PROGRAM:
      // Serial.println("MEASUREMENT");
      Serial.println("\n\nProgramma completato!");
      delay(1000);
      exit(0);
      break;
    default:
      Serial.println("\n...Invalid Program Phase...");
      delay(5000);
      break;
    }

    delay(5000);
  }
}

#line 1 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\HX711_management.ino"
void selectLoadcell()
{
  bool valid = false;
  while (!valid)
  {
    Serial.print("\nInserire fondoscala della cella di carico [kg]...");
    // flush the serial buffer
    // while (Serial.available() > 0)
    // {
    //   Serial.read();
    // }
    // // await for value to be inserted
    // while (Serial.available() == 0)
    // {
    //   ;
    // }
    awaitKeyPressed();
    int in = Serial.parseInt();
    if (in == 1 || in == 3 || in == 10 || in == 50)
    {
      FULLSCALE = in;
      valid = true;
    }
    else
    {
      Serial.println("\nFondoscala invalido...");
      delay(3000);
    }
  }
  // Serial.print("\nFondoscala: ");
  // Serial.print(FULLSCALE);
  Serial.println(FULLSCALE);
}

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
#line 1 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_Modbus_HX711\\SMD1204_Functions.ino"
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
    Serial.println("\n\nCOMMAND NOT SENDED!\n");
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
    splitU32to16(acc_ramp);
    if (!(modbusTCPClient.holdingRegisterWrite(Racc, splitted[0]) && modbusTCPClient.holdingRegisterWrite(Racc + 1, splitted[1])))
    {
      Serial.println("\nFailed to disable acceleration ramp");
    }
    if (!(modbusTCPClient.holdingRegisterWrite(Rdec, splitted[0]) && modbusTCPClient.holdingRegisterWrite(Rdec + 1, splitted[1])))
    {
      Serial.println("\nFailed to disable deceleration ramp");
    }
    PHASE = PARAMETERS;
    // PHASE = HOMING;
  }
}

void parametersSettings()
{
  Serial.println("---------------------------");
  Serial.println("----SETTAGGIO PARAMETRI----");
  Serial.println("---------------------------");

  Serial.print("\nInserire massimo spostamento negativo [mm]... ");
  awaitKeyPressed();
  min_pos = Serial.parseFloat();
  Serial.println(min_pos);

  Serial.print("Inserire massimo spostamento positivo [mm]... ");
  awaitKeyPressed();
  max_pos = Serial.parseFloat();
  Serial.println(max_pos);

  Serial.print("Inserire numero di punti PARI desiderati... ");
  awaitKeyPressed();
  num_pos = Serial.parseInt();
  if (num_pos % 2 == 1)
    num_pos++;
  Serial.println(num_pos);

  // populate array of spacial mesh
  populatePosArray();
  // delay(5000);
  // allocate in memory array of sorted positions and force
  sortArray();

  meas_force = (float *)malloc(num_pos * sizeof(float *));

  Serial.println("\nSi desidera mediare i piccoli spostamenti? (S)/N");
  awaitKeyPressed();
  int ans = Serial.read();
  if (isUpperCase(ans))
    ans = tolower(ans);
  switch (char(ans))
  {
  case 'n':
    mean_active = false;
    Serial.println("Mediazione disattivata");
    break;
  default:
    mean_active = true;
    Serial.println("Mediazione attivata");
    break;
  }
  Serial.println("---------------------------");

  PHASE = HOMING;
}

void homingRoutine()
{
  // measure the 0 point with spider mounted alone
  // press enter
  // clamp the spider
  // press enter
  // seek the position in which the value of hx711 is equal to unclamped (in error band)
  sendCommand(home());

  Serial.println("\nPorre il centratore sulla cella...");
  Serial.println("Premere enter");
  awaitKeyPressed();

  float tare = getForce();
  delay(1000);
  Serial.println("Clampare il centratore...");
  Serial.println("Premere enter");
  awaitKeyPressed();

  float clamped = getForce();
  // Serial.print("Tara: ");
  // Serial.println(tare, 6);
  // Serial.print("Clampata: ");
  // Serial.println(clamped, 6);

  float err = fabs(clamped - tare);
  // Serial.print("Errore: ");
  // Serial.println(err, 6);
  // Serial.print("Soglia: ");
  // Serial.println(fabs(home_err * tare));

  // assuming loadcell reads x<0 when extended and x>0 when compressed
  int32_t pos;
  if (err > 0)
    pos = -128;
  else
    pos = 128;
  split32to16(pos);
  if (!(modbusTCPClient.holdingRegisterWrite(Rpostarg, splitted[0]) && modbusTCPClient.holdingRegisterWrite(Rpostarg + 1, splitted[1])))
  {
    Serial.println("\nErrore nel settaggio posizione...");
  }

  while (err > fabs(home_err * tare))
  {
    sendCommand(gor());
    delay(100);
    clamped = getForce();
    err = fabs(clamped - tare);
    // Serial.println(err, 6);
  }
  tare_force = clamped;
  init_pos = getPosact();
  Serial.print("Init pos: ");
  Serial.println(init_pos);
  PHASE = MEASUREMENT;
}

// TODO: create routine
void measureRoutine()
{
  // measuring
  // intially we'll develop a   routine that will move-stop-measure-move-stop-measure and so on
  // TODO: implementare la media delle misure cazzzzooo
  sendPosTarget(init_pos + mm2int(pos_sorted[pos_idx]));
  sendCommand(go());
  getStatus();
  // printStatus();
  // Serial.println(sts, BIN);

  // engine in position
  if (bitRead(sts, 3) && !bitRead(sts, 10))
  {
    // Serial.println(sts, BIN);
    Serial.println("CULO");
  }
  else
  {
    Serial.print("FERMO ");
    // printStatus();
    // wait 500 ms
    // delay(500);

    // take the measure
    meas_force[pos_idx] = getForce();
    Serial.print("IDX: ");
    Serial.print(pos_idx);
    Serial.print(" Force at ");
    Serial.print(getPosact());
    Serial.print(" pos ");
    Serial.print(pos_sorted[pos_idx]);
    Serial.print(" is ");
    Serial.print(meas_force[pos_idx]);
    Serial.println(" N");

    //   /* if (mean_active)
    //   {
    //     // routine della media
    //   } */
    pos_idx++;
    //   // }
  }
  if (pos_idx == num_pos)
  {
    PHASE = END_PROGRAM;
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
    Serial.println("Errore nella scrittura della posizione");
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

void populatePosArray()
{
  float mesh_size = (max_pos - min_pos) / (num_pos - 1);
  meas_pos = (float *)malloc(num_pos * sizeof(float));
  for (int i = 0; i < num_pos; i++)
  {
    meas_pos[i] = min_pos + mesh_size * i;
    Serial.print(meas_pos[i]);
    Serial.print(" ");
  }
  Serial.print("\n");
}

void sortArray()
{

  pos_sorted = (float *)malloc(num_pos * sizeof(float));
  int init = num_pos / 2;
  int idx = 0;
  // sort array
  for (int j = 0; j < num_pos; j++)
  {
    if (j > 0 && j % 2 == 0)
    {
      idx = j / 2;
    }
    else if (j % 2 > 0)
    {
      idx = -(j + 1) / 2;
    }

    idx = init + idx;

    pos_sorted[j] = meas_pos[idx];
    Serial.print(pos_sorted[j]);
    Serial.print(" ");
  }
  Serial.print("\n");
}
