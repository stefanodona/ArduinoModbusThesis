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
const int32_t vel = 10;       // rps
const int32_t vel_tare = 0.1; // rps
const uint32_t acc_ramp = 10; // no acceleration ramp

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

float th1 = 0; // threshold for the averaging
float th2 = 0;
float th3 = 0;

int cnt_th1 = 0; // measures to take for each average
int cnt_th2 = 0;
int cnt_th3 = 0;

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
    while (Serial.readStringUntil("\n") != "Ready to write\n")
    {
        ;
    }

    flushSerial();
    Serial.write("Parameters\n");

    // flushSerial();
    // Serial.write("loadcell\n");
    // FULLSCALE = Serial.parseInt();

    // // flushSerial();
    // Serial.write("min_pos\n");
    // min_pos = Serial.parseFloat();

    // // flushSerial();
    // Serial.write("max_pos\n");
    // max_pos = Serial.parseFloat();

    // // flushSerial();
    // Serial.write("num_pos\n");
    // num_pos = Serial.parseInt();

    // // flushSerial();
    // Serial.write("media\n");
    // mean_active = bool(Serial.parseInt());

    // // flushSerial();
    // Serial.write("a_r\n");
    // ar_flag = bool(Serial.parseInt());
    // Serial.println(ar_flag);
    FULLSCALE = Serial.parseInt(SKIP_WHITESPACE);
    min_pos = Serial.parseFloat(SKIP_WHITESPACE);
    max_pos = Serial.parseFloat(SKIP_WHITESPACE);
    num_pos = Serial.parseInt(SKIP_WHITESPACE);
    mean_active = bool(Serial.parseInt(SKIP_WHITESPACE));
    ar_flag = bool(Serial.parseInt(SKIP_WHITESPACE));
    th1 = Serial.parseFloat(SKIP_WHITESPACE);
    cnt_th1 = Serial.parseInt(SKIP_WHITESPACE);
    th2 = Serial.parseFloat(SKIP_WHITESPACE);
    cnt_th2 = Serial.parseInt(SKIP_WHITESPACE);
    th3 = Serial.parseFloat(SKIP_WHITESPACE);
    cnt_th3 = Serial.parseInt(SKIP_WHITESPACE);

    flushSerial();

    // Serial.println(FULLSCALE);
    // Serial.println(min_pos);
    // Serial.println(max_pos);
    // Serial.println(num_pos);
    // Serial.println(mean_active);
    // Serial.println(ar_flag);
    // Serial.println(th1);
    // Serial.println(cnt_th1);
    // Serial.println(th2);
    // Serial.println(cnt_th2);
    // Serial.println(th3);
    // Serial.println(cnt_th3);

    // flushSerial();

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