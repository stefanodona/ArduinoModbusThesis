// COMPILER DIRECTIVES

#include <SPI.h>
#include <Ethernet3.h>
#include <ArduinoRS485.h> // ArduinoModbus depends on the ArduinoRS485 library
#include <ArduinoModbus.h>
#include <HX711.h>

// USEFUL REGISTERS
#define Rposact 0    // actual position
#define Rpostarg 8   // target position
#define Rhofs 36     // offset position after homing
#define Rcmdwr 59    // command register
#define Rvel 63      // traslation speed
#define Racc 67      // acceleration ramp
#define Rdec 70      // deceleration ramp
#define Rhmode 82    // home mode selection
#define Rstsflg 199  // status flags
#define Rstscllp 203 // closed loop status flags
#define Ralarm 227   // alarms flags

// HX711 pins
#define DT_PIN A0
#define SCK_PIN A1

//-------------------------------------------------

// USEFUL CONSTANT
const int32_t vel = 10;       // rps
const int32_t vel_tare = 1;   // rps
const uint32_t acc_ramp = 10; // no acceleration ramp

const float home_err = 0.05; // 5% error band to retrieve the no-force initial position
// int32_t home_pos = 0.5;
float home_pos = 0.5;

// VARIABLES
uint16_t sts = 0;      // status of the driver
uint16_t sts_cllp = 0; // status of the driver
float target = 0;      // target position [mm]
float tare_force = 0;  // tare measured before taking any measurement
int32_t init_pos = 0;  // value of the initial position

int8_t FULLSCALE = 1;          // the fullscale of the loadcell
float min_pos = 0;             // minimal position in spacial axis
float max_pos = 0;             // maximal position in spacial axis
int num_pos = 0;               // # of spacial points
unsigned long waitTime = 3000; // wait time after which measure

uint8_t pos_idx = 0; // index to navigate the pos_sorted array
float sum_p = 0;
float sum_m = 0;

float th1 = 0; // threshold for the averaging
float th2 = 0;
float th3 = 0;
float zero_approx = 0;

// weight of supports [in grams]
float up_disk_weight = 0;
float dw_disk_weight = 0;
float vc_coil_weight = 0;

int cnt_th1 = 0; // measures to take for each average
int cnt_th2 = 0;
int cnt_th3 = 0;
int cnt_zero = 0;

float vel_max = 0;  // maximum translation velocity
float acc_max = 0;  // maximum acceleration ramp
float time_max = 0; // maximum time of translation

// FLAGS
bool stat_creep_flag = false;
bool mean_active = false;
bool ar_flag = false;
bool vel_flag = true;
bool time_flag = false;
bool search_active = true;
bool tracking_flag = false;

bool resetting_piston = false;

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

void (*resetFunc)(void) = 0;

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
    delay(100);

    while (true)
    {
        if (Serial.available())
        {
            String msg = Serial.readString();
            if (msg == "Ready to write\n")
            {
                break;
            }
            else if (msg=="GO HOME\n"){
                resetting_piston = true;
                goto skip_parameters;
            }
        }
    }


    delay(100);

    // flushSerial();
    Serial.write("Parameters\n");

    stat_creep_flag = bool(Serial.parseInt(SKIP_WHITESPACE));
    FULLSCALE = Serial.parseInt(SKIP_WHITESPACE);
    min_pos = Serial.parseFloat(SKIP_WHITESPACE);
    max_pos = Serial.parseFloat(SKIP_WHITESPACE);
    num_pos = Serial.parseInt(SKIP_WHITESPACE);
    waitTime = (unsigned long)(Serial.parseInt(SKIP_WHITESPACE));
    mean_active = bool(Serial.parseInt(SKIP_WHITESPACE));
    ar_flag = bool(Serial.parseInt(SKIP_WHITESPACE));
    tracking_flag = bool(Serial.parseInt(SKIP_WHITESPACE));

    th1 = Serial.parseFloat(SKIP_WHITESPACE);
    cnt_th1 = Serial.parseInt(SKIP_WHITESPACE);
    th2 = Serial.parseFloat(SKIP_WHITESPACE);
    cnt_th2 = Serial.parseInt(SKIP_WHITESPACE);
    th3 = Serial.parseFloat(SKIP_WHITESPACE);
    cnt_th3 = Serial.parseInt(SKIP_WHITESPACE);

    zero_approx = Serial.parseFloat(SKIP_WHITESPACE);
    cnt_zero = Serial.parseInt(SKIP_WHITESPACE);

    vel_flag = bool(Serial.parseInt(SKIP_WHITESPACE));
    vel_max = Serial.parseFloat(SKIP_WHITESPACE);
    acc_max = Serial.parseFloat(SKIP_WHITESPACE);
    time_flag = bool(Serial.parseInt(SKIP_WHITESPACE));
    time_max = Serial.parseFloat(SKIP_WHITESPACE);

    search_active = bool(Serial.parseInt(SKIP_WHITESPACE));

    up_disk_weight = Serial.parseFloat(SKIP_WHITESPACE);
    dw_disk_weight = Serial.parseFloat(SKIP_WHITESPACE);
    vc_coil_weight = Serial.parseFloat(SKIP_WHITESPACE);

    float FS = float(FULLSCALE);

    sendMessage("LOADCELL: ", &FS, NULL, NULL);

    flushSerial();

    vel_max = constrain(vel_max, 0.1, 10);

    // flushSerial();

    // ----------------------------------------------
    skip_parameters:
    // initialize loadcell
    loadcell.begin(DT_PIN, SCK_PIN);
    // loadcell.set_gain((uint32_t)128, true);

    // ----------------------------------------------

    // Init IP communication
    Serial.println(tracking_flag);
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

    if (resetting_piston){
        resetPiston();
        Serial.println("HOMED");
        resetFunc();
    }

    // HOMING ROUTINE
    homingRoutine();

    // MEASURE ROUTINE
    delay(500);
    if (stat_creep_flag)
        creepRoutine();
    else
    {
        if (tracking_flag)
            trackingRoutine();
        else
            measureRoutine();
    }

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
    Serial.println(time + (t2 - t1));
}

