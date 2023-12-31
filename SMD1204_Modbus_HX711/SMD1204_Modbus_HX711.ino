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
const int8_t SETUP_DRIVE = 0; // program phases
const int8_t PARAMETERS = 1;
const int8_t HOMING = 2;
const int8_t MEASUREMENT = 3;
const int8_t END_PROGRAM = 4;

const int32_t vel = 10;      // rps
const uint32_t acc_ramp = 0; // no acceleration ramp

const float home_err = 0.05; // 5% error band to retrieve the no-force initial position

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
float sum_p = 0;
float sum_m = 0;
float avg_thr = 5;          // mm below which is done an average measure
uint8_t cnt = 4;            // 

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
  // Ethernet.begin(mac, server);
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
