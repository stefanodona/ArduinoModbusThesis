# 1 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_noLoop.ino"
// COMPILER DIRECTIVES

# 4 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_noLoop.ino" 2
# 5 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_noLoop.ino" 2
# 6 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_noLoop.ino" 2
# 7 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_noLoop.ino" 2
# 8 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_noLoop.ino" 2

// USEFUL REGISTERS
# 22 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_noLoop.ino"
// HX711 pins



//-------------------------------------------------

// USEFUL CONSTANT
const int32_t vel = 10; // rps
const int32_t vel_tare = 1; // rps
const uint32_t acc_ramp = 10; // no acceleration ramp

const float home_err = 0.05; // 5% error band to retrieve the no-force initial position
// int32_t home_pos = 0.5;
float home_pos = 0.5;

// VARIABLES
uint16_t sts = 0; // status of the driver
uint16_t sts_cllp = 0; // status of the driver
float target = 0; // target position [mm]
float tare_force = 0; // tare measured before taking any measurement
int32_t init_pos = 0; // value of the initial position

int8_t FULLSCALE = 1; // the fullscale of the loadcell
float min_pos = 0; // minimal position in spacial axis
float max_pos = 0; // maximal position in spacial axis
int num_pos = 0; // # of spacial points
unsigned long waitTime = 3000; // wait time after which measure

uint8_t pos_idx = 0; // index to navigate the pos_sorted array
float sum_p = 0;
float sum_m = 0;

float th1 = 0; // threshold for the averaging
float th2 = 0;
float th3 = 0;
float zero_approx = 0;

int cnt_th1 = 0; // measures to take for each average
int cnt_th2 = 0;
int cnt_th3 = 0;
int cnt_zero = 0;

float vel_max = 0; // maximum translation velocity
float acc_max = 0; // maximum acceleration ramp
float time_max = 0; // maximum time of translation

// FLAGS
bool stat_creep_flag = false;
bool mean_active = false;
bool ar_flag = false;
bool vel_flag = true;
bool time_flag = false;
bool search_active = true;

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

void(* resetFunc)(void)=0;

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
    // while (Serial.readStringUntil("\n") != "Ready to write\n")
    // {
    //     if (Serial.available()){
    //         Serial.println(Serial.readString());
    //     }
    //     // Serial.println("oi");
    // }

    while (true)
    {
        if (Serial.available())
        {
            String msg = Serial.readString();
            if (msg == "Ready to write\n")
            {
                break;
            }
        }
    }

    delay(100);

    // flushSerial();
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
    stat_creep_flag = bool(Serial.parseInt(SKIP_WHITESPACE));
    FULLSCALE = Serial.parseInt(SKIP_WHITESPACE);
    min_pos = Serial.parseFloat(SKIP_WHITESPACE);
    max_pos = Serial.parseFloat(SKIP_WHITESPACE);
    num_pos = Serial.parseInt(SKIP_WHITESPACE);
    waitTime = (unsigned long)(Serial.parseInt(SKIP_WHITESPACE));
    mean_active = bool(Serial.parseInt(SKIP_WHITESPACE));
    ar_flag = bool(Serial.parseInt(SKIP_WHITESPACE));

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

    Serial.println(stat_creep_flag);
    Serial.println("zer0_approx");
    Serial.println(zero_approx);
    Serial.println("cnt_zer0");
    Serial.println(cnt_zero);

    flushSerial();

    vel_max = ((vel_max)<(0.1)?(0.1):((vel_max)>(10)?(10):(vel_max)));

    // flushSerial();

    // ----------------------------------------------

    // initialize loadcell
    loadcell.begin(A0, A1);
    // loadcell.set_gain((uint32_t)128, true);

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
    if (stat_creep_flag)
        creepRoutine();
    else
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
# 1 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\HX711_Functions.ino"
float getForce()
{
  float force = 0;
  // while (!loadcell.is_ready())
  // {
  // }
  float val=0;
  if (stat_creep_flag) val = loadcell.read();
  else val = loadcell.read_average(5);
  // float val = loadcell.read();
  // float val = avg(5);
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
  return -force;
}

// insert poynomials coefficients computed for each load cell
// x is the number read from the loadcell
float getForce1(float x)
{
  // FIXME: insert the right ones
  float a = 2.35491e-08;
  float b = 0.0237357;
  float c = -0.442871;
  float force = a * x * x + b * x + c;
  return force;
}

float getForce3(float x)
{
  float a = 0;
  float b = 7.540505*pow(10, -6);
  float c = -2.664501*pow(10, -3);
  float force = a * x * x + b * x + c;
  return force;
  // return x;
}

float getForce10(float x)
{
  float a = 0;
  float b = 7.540505*pow(10, -6)*10/3; // vecchio
  // float b = 2.708316*pow(10, -5);
  float c = 0;
  float force = a * x * x + b * x + c;
  return force;
}

float getForce50(float x)
{
  float a = 0;
  float b = 0;
  float c = 0;
  float force = a * x * x + b * x + c;
  return force;
}

float avg(int times)
{
  float sum = 0;
  if (times < 1)
  {
    times = 1;
  }
  for (int i = 0; i < times; i++)
  {
    sum += loadcell.read();
  }
  return sum / times;
}
# 1 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
uint16_t splitted[2]; // utility array to split a 32 bit data into 2x16 bit data

uint16_t disableDrive()
{
  uint16_t cmd = 0;
  ((1) ? (((cmd)) |= (1UL << ((0)))) : (((cmd)) &= ~(1UL << ((0)))));
  return cmd;
}

uint16_t enableDrive()
{
  uint16_t cmd = 0;
  ((1) ? (((cmd)) |= (1UL << ((1)))) : (((cmd)) &= ~(1UL << ((1)))));
  return cmd;
}

uint16_t abortDrive()
{
  uint16_t cmd = 0;
  ((1) ? (((cmd)) |= (1UL << ((2)))) : (((cmd)) &= ~(1UL << ((2)))));
  return cmd;
}

uint16_t stop()
{
  uint16_t cmd = 0;
  ((1) ? (((cmd)) |= (1UL << ((3)))) : (((cmd)) &= ~(1UL << ((3)))));
  return cmd;
}

uint16_t go()
{
  uint16_t cmd = 0;
  ((1) ? (((cmd)) |= (1UL << ((7)))) : (((cmd)) &= ~(1UL << ((7)))));
  return cmd;
}

uint16_t gor()
{
  uint16_t cmd = 0;
  ((1) ? (((cmd)) |= (1UL << ((8)))) : (((cmd)) &= ~(1UL << ((8)))));
  return cmd;
}

uint16_t home()
{
  uint16_t cmd = 0;
  ((1) ? (((cmd)) |= (1UL << ((9)))) : (((cmd)) &= ~(1UL << ((9)))));
  return cmd;
}

// function to send a command in the Rcmdwr register
void sendCommand(uint16_t cmd)
{
  if (modbusTCPClient.holdingRegisterWrite(59 /* command register*/, cmd))
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
  modbusTCPClient.holdingRegisterWrite(227 /* alarms flags*/, 0);
  // modbusTCPClient.holdingRegisterWrite(Rpostarg, int16_t(0));
  // modbusTCPClient.holdingRegisterWrite(Rpostarg + 1, int16_t(0));
  sendPosTarget((int32_t)0);

  // check status
  if (modbusTCPClient.holdingRegisterRead(199 /* status flags*/) != -1)
  {
    sts = modbusTCPClient.holdingRegisterRead(199 /* status flags*/);
  }

  // enable drive if disabled
  while (!(((sts) >> (0)) & 0x01))
  {
    sendCommand(enableDrive());
    getStatus();
  }

  // DEVICE ENABLED - SETTINGS HERE
  // Home Method
  split32to16(mm2int(0));
  modbusTCPClient.holdingRegisterWrite(36 /* offset position after homing*/, splitted[0]);
  modbusTCPClient.holdingRegisterWrite(36 /* offset position after homing*/ + 1, splitted[1]);
  // modbusTCPClient.holdingRegisterWrite(Rhmode, (int16_t)(-9)); // in battuta indietro
  modbusTCPClient.holdingRegisterWrite(82 /* home mode selection*/, (int16_t)0); // azzeramento sul posto

  // velocity setting - rps*100
  split32to16(vel * 100);
  if (modbusTCPClient.holdingRegisterWrite(63 /* traslation speed*/, splitted[0]) && modbusTCPClient.holdingRegisterWrite(63 /* traslation speed*/ + 1, splitted[1]))
  {
    Serial.print("Velocita' massima settata a: ");
    Serial.print(vel);
    Serial.println(" rps");
  }

  // setting acceleration ramp
  splitU32to16(acc_ramp * 100);
  if (!(modbusTCPClient.holdingRegisterWrite(67 /* acceleration ramp*/, splitted[0]) && modbusTCPClient.holdingRegisterWrite(67 /* acceleration ramp*/ + 1, splitted[1])))
  {
    Serial.write("Failed to disable acceleration ramp\n");
  }
  if (!(modbusTCPClient.holdingRegisterWrite(70 /* deceleration ramp*/, splitted[0]) && modbusTCPClient.holdingRegisterWrite(70 /* deceleration ramp*/ + 1, splitted[1])))
  {
    Serial.write("Failed to disable deceleration ramp\n");
  }
}

void homingRoutine()
{
  // setting velocity to seek the tare position
  split32to16(vel_tare * 10);
  if (modbusTCPClient.holdingRegisterWrite(63 /* traslation speed*/, splitted[0]) && modbusTCPClient.holdingRegisterWrite(63 /* traslation speed*/ + 1, splitted[1]))
  {
  }
  // seek the position in which the value of hx711 is equal to unclamped (in error band)
  sendCommand(home());

  // Serial.write("Togliere il centratore dalla cella...\n");
  // // Serial.write("Premere enter\n");
  // awaitKeyPressed();

  // float tare = getForce();
  // // tare = getForce3(373950);
  // delay(1000);
  // sendPosTarget(mm2int(-10));
  // sendCommand(gor());
  // getStatus();
  //     while (bitRead(sts, 3))
  //       // checkPanic();
  //       getStatus();

  Serial.write("Posizionare il centratore...\n");
  awaitKeyPressed();
  String inc_msg = Serial.readString();
  if (inc_msg!="ok\n")
  {
    flushSerial();
    Serial.flush();
    Serial.end();
    // return;
    resetFunc();
  }


  float tare = getForce();

  Serial.write("Stringere il centratore...\n");
  awaitKeyPressed();
  inc_msg = Serial.readString();
  if (inc_msg!="ok\n")
  {
    flushSerial();
    Serial.flush();
    Serial.end();
    // return;
    resetFunc();
  }

  float clamped = getForce();

  Serial.println("Clamped");
  Serial.println(clamped, 6);
  Serial.println("T4re");
  Serial.println(tare, 6);

  // assuming loadcell reads x<0 when extended and x>0 when compressed
  float pos;
  if (clamped > tare)
    pos = -home_pos;
  else
    pos = home_pos;

  // sendPosTarget(mm2int(pos*4));
  sendPosTarget(mm2int(pos));

  Serial.write("Taratura\n");
  float abs_tol = 0.1; // [N] tolerance
  // bool search_active = true;
  // float disks_weight = (0.12995+0.1083+0.02543)*9.81;
  float disks_weight = (0.12995+0.1083+0.02027)*9.81;
  // float disks_weight = (0.12995 + 0.1083) * 9.81;
  tare -= disks_weight;

  // tare += disks_weight;

  if (search_active)
  {
    float div[] = {1, 5, 20}; // 3 cycles of refinement 1, 1/5, 1/20 of abs_tol
    for (int i = 0; i < 3; i++)
    {
      float upperBound = tare + abs_tol / div[i];
      float lowerBound = tare - abs_tol / div[i];

      do
      {
        sendCommand(gor());
        getStatus();

        while ((((sts) >> (3)) & 0x01))
        {
          getStatus();
        }
        delay(500);

        float post_moved = getForce();
        float diff = (post_moved - clamped) / pos;

        pos = ((tare - post_moved) / diff);
        pos = ((pos)<(-1.0)?(-1.0):((pos)>(1.0)?(1.0):(pos)));

        // Serial.println("diff: ");
        // Serial.println(diff, 5);
        Serial.println("pos realtiva prossimo passo:");
        Serial.println(pos, 5);
        Serial.println("forza mancante: ");
        Serial.println((tare - post_moved), 5);
        Serial.println("post_moved: ");
        Serial.println(post_moved, 5);
        Serial.println("lowerbound: ");
        Serial.println(lowerBound, 5);
        Serial.println("upperbound: ");
        Serial.println(upperBound, 5);

        sendPosTarget(mm2int(pos));
        clamped = post_moved;
        // delay(200);
        Serial.println("____");
      } while (clamped < lowerBound || clamped > upperBound);

      delay(10000);
    }
  }

  // tare_force = clamped;
  tare_force = getForce();

  // sendPosTarget(mm2int(1));
  // sendCommand(go());
  // getStatus();
  // while (bitRead(sts, 3))
  //   // checkPanic();
  //   getStatus();

  sendCommand(home());

  getStatus();
  while ((((sts) >> (15)) & 0x01))
  {
    getStatus();
  }

  init_pos = getPosact();
  Serial.println("init pos");
  Serial.println(init_pos);

  // Serial.println("Init Pos: ");
  // Serial.println(init_pos);
  String msg = "tare ";
  // char num[15];
  // dtostrf(tare_force, 10, 6, num);
  // Serial.println(msg + num);

  sendMessage("tare", tare_force, 
# 270 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino" 3 4
                                 __null
# 270 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
                                     , 
# 270 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino" 3 4
                                       __null
# 270 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
                                           );

  split32to16(vel * 100);
  if (modbusTCPClient.holdingRegisterWrite(63 /* traslation speed*/, splitted[0]) && modbusTCPClient.holdingRegisterWrite(63 /* traslation speed*/ + 1, splitted[1]))
  {
  }
}

void measureRoutine()
{
  Serial.write("Measure Routine\n");
  // inizializziamo qua
  float pos[num_pos];
  flushSerial();
  Serial.write("send me\n");

  for (int i = 0; i < num_pos; i++)
  {
    pos[i] = Serial.parseFloat(SKIP_WHITESPACE);
    Serial.println(pos[i]);
  }

  float sum_p = 0;
  float sum_m = 0;
  float sum_sq_p = 0;
  float sum_sq_m = 0;

  float sum_pos_p = 0;
  float sum_pos_m = 0;
  float sum_sq_pos_p = 0;
  float sum_sq_pos_m = 0;

  String msg = "val ";
  String msg_pos = "driver_pos ";
  String msg_std = "std ";

  String msg_zero = "zero ";
  // String msg_zero_pos = "zero_p ";

  // String msg_std_pos = "std_pos ";
  // char buff[15];
  char num[15];
  char zero_buff_pos[15];
  char zero_buff_force[15];
  char std1[15];
  char std2[15];

  Serial.write("Measuring\n");

  unsigned long tik = millis();
  unsigned long tok = 0;
  unsigned long tiktok = 0;

  Serial.write("andata\n");
  for (int i = 0; i < num_pos; i = i + 2)
  {
    int cnt = getAvgCnt(pos[i]);
    checkModbusConnection();
    setAccVelocity(pos[i]);

    Serial.println("cnt ");
    Serial.println(cnt);

    float k_f_p = 0;
    float k_f_m = 0;
    float k_p_p = 0;
    float k_p_m = 0;

    float Ex_p = 0;
    float Ex_m = 0;
    float Ey_p = 0;
    float Ey_m = 0;

    float prev_x_p = fabs(pos[i]);
    float prev_x_m = fabs(pos[i + 1]);

    for (int j = 0; j < cnt; j++)
    {

      // positive movement (up)
      sendPosTarget(init_pos + mm2int(pos[i]));
      sendCommand(go());
      getStatus();
      while ((((sts) >> (3)) & 0x01))
        // checkPanic();
        getStatus();

      sendCommand(disableDrive());

      delay(waitTime);

      // Measure rise time
      tok=millis();
      tiktok = tok-tik;
      String t_rise = "t_r";
      sendMessage(t_rise, float(tiktok), pos[i], 
# 365 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino" 3 4
                                                __null
# 365 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
                                                    );

      // Measure position and force
      float x_p = int2mm(getPosact() - init_pos);
      float y_p = getForce() - tare_force;

      if (j == 0)
      {
        k_p_p = x_p;
        k_f_p = y_p;
      }

      sum_pos_p += x_p;
      sum_p += y_p;
      Ex_p += x_p - k_p_p;
      Ey_p += y_p - k_f_p;
      sum_sq_pos_p += pow(x_p - k_p_p, 2);
      sum_sq_p += pow(y_p - k_f_p, 2);

      Serial.println("x_p: ");
      Serial.println(x_p, 6);
      Serial.println("Ex_p: ");
      Serial.println(Ex_p, 6);
      Serial.println("sum_sq_pos_p: ");
      Serial.println(sum_sq_pos_p, 6);
      // unsigned long tok = millis();
      // long tikketokke = tok - tik;
      // Serial.write("TikkeTokke\n");
      // Serial.println(tikketokke);

      Serial.write("check percent\n");

      getStatus();
      while (!(((sts) >> (0)) & 0x01))
      {
        getStatus();
        sendCommand(enableDrive());
      }

      // Measure fall time
      tok=millis();
      tiktok = tok-tik;
      String t_fall = "t_f";
      sendMessage(t_fall, float(tiktok), pos[i], 
# 408 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino" 3 4
                                                __null
# 408 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
                                                    );

      sendPosTarget(init_pos);
      sendCommand(go());
      getStatus();
      while ((((sts) >> (3)) & 0x01))
        getStatus();

      // negative movement (down)
      sendPosTarget(init_pos + mm2int(pos[i + 1]));
      sendCommand(go());
      getStatus();
      while ((((sts) >> (3)) & 0x01))
        // checkPanic();
        getStatus();
      sendCommand(disableDrive());
      delay(waitTime);

      // Measure rise time
      tok=millis();
      tiktok = tok-tik;
      // String t_rise = "t_r";
      sendMessage(t_rise, float(tiktok), pos[i+1], 
# 430 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino" 3 4
                                                  __null
# 430 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
                                                      );

      // measure position and force
      float x_m = int2mm(getPosact() - init_pos);
      float y_m = getForce() - tare_force;

      if (j == 0)
      {
        k_p_m = x_m;
        k_f_m = y_m;
      }

      sum_pos_m += x_m;
      sum_m += y_m;
      Ex_m += x_m - k_p_m;
      Ey_m += y_m - k_f_m;
      sum_sq_pos_m += pow(x_m - k_p_m, 2);
      sum_sq_m += pow(y_m - k_f_m, 2);

      Serial.println("x_m: ");
      Serial.println(x_m, 6);
      Serial.println("Ex_m: ");
      Serial.println(Ex_m, 6);
      Serial.println("sum_sq_pos_m: ");
      Serial.println(sum_sq_pos_m, 6);

      Serial.write("check percent\n");

      getStatus();
      while (!(((sts) >> (0)) & 0x01))
      {
        getStatus();
        sendCommand(enableDrive());
      }

      // Measure rise time
      tok=millis();
      tiktok = tok-tik;
      // String t_fall = "t_f";
      sendMessage(t_fall, float(tiktok), pos[i+1], 
# 469 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino" 3 4
                                                  __null
# 469 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
                                                      );

      sendPosTarget(init_pos);
      sendCommand(go());
      getStatus();
      while ((((sts) >> (3)) & 0x01))
        getStatus();

      // check to read consistent data
      if ((fabs(x_p) > 2 * prev_x_p || fabs(x_m) > 2 * prev_x_m))
      {
        // delete data from the cumulative quantities and redo the measure
        Serial.println("ErrorPos");
        sum_pos_p -= x_p;
        sum_p -= y_p;
        Ex_p -= x_p - k_p_p;
        Ey_p -= y_p - k_f_p;
        sum_sq_pos_p -= pow(x_p - k_p_p, 2);
        sum_sq_p -= pow(y_p - k_f_p, 2);

        sum_pos_m -= x_m;
        sum_m -= y_m;
        Ex_m -= x_m - k_p_m;
        Ey_m -= y_m - k_f_m;
        sum_sq_pos_m -= pow(x_m - k_p_m, 2);
        sum_sq_m -= pow(y_m - k_f_m, 2);
        j--;
      }

      delay(waitTime);
      float zero_val = getForce() - tare_force;
      float zero_pos = int2mm(getPosact() - init_pos);

      dtostrf(zero_val, 10, 6, zero_buff_force);
      dtostrf(zero_pos, 10, 6, zero_buff_pos);
      String tosend = "r " + msg_zero + zero_buff_force + " " + zero_buff_pos + "\n";
      Serial.println(tosend);
    }

    float meas_p = sum_p / cnt;
    float meas_m = sum_m / cnt;
    float pos_p = sum_pos_p / cnt;
    float pos_m = sum_pos_m / cnt;

    float var_f_p = 0;
    float var_f_m = 0;
    float var_pos_p = 0;
    float var_pos_m = 0;

    float std_f_p = 0;
    float std_f_m = 0;
    float std_pos_p = 0;
    float std_pos_m = 0;

    if (cnt > 1)
    {
      var_f_p = (sum_sq_p - pow(Ey_p, 2) / cnt) / (cnt - 1);
      var_f_m = (sum_sq_m - pow(Ey_m, 2) / cnt) / (cnt - 1);
      var_pos_p = (sum_sq_pos_p - pow(Ex_p, 2) / cnt) / (cnt - 1);
      var_pos_m = (sum_sq_pos_m - pow(Ex_m, 2) / cnt) / (cnt - 1);

      std_f_p = sqrtf(var_f_p);
      std_f_m = sqrtf(var_f_m);
      std_pos_p = sqrtf(var_pos_p);
      std_pos_m = sqrtf(var_pos_m);
    }

    //////////////////////////////////

    dtostrf(meas_p, 10, 6, num);
    Serial.println(msg + num);

    dtostrf(std_f_p, 10, 6, std1);
    dtostrf(std_pos_p, 10, 6, std2);
    Serial.println(msg_std + std1 + " " + std2);

    dtostrf(pos_p, 10, 6, num);
    Serial.println(msg_pos + num);

    //////////////////////////////////

    dtostrf(meas_m, 10, 6, num);
    Serial.println(msg + num);

    dtostrf(std_f_m, 10, 6, std1);
    dtostrf(std_pos_m, 10, 6, std2);
    Serial.println(msg_std + std1 + " " + std2);

    dtostrf(pos_m, 10, 6, num);
    Serial.println(msg_pos + num);

    sum_p = 0;
    sum_m = 0;
    sum_pos_p = 0;
    sum_pos_m = 0;
    sum_sq_p = 0;
    sum_sq_m = 0;
    sum_sq_pos_p = 0;
    sum_sq_pos_m = 0;
  }

  // delay(waitTime);
  // tare_force = getForce();
  // float pos_0 = int2mm(getPosact());
  // Serial.println("Ritorno T4re:");
  // Serial.println(tare_force, 5);
  // Serial.println("Pos prima del ritorno:");
  // Serial.println(pos_0, 5);

  if (ar_flag)
  {
    Serial.write("ritorno\n");
    for (int i = num_pos - 1; i >= 0; i = i - 2)
    {
      int cnt = getAvgCnt(pos[i]);
      checkModbusConnection();
      setAccVelocity(pos[i]);

      Serial.println("cnt ");
      Serial.println(cnt);

      float k_f_p = 0;
      float k_f_m = 0;
      float k_p_p = 0;
      float k_p_m = 0;

      float Ex_p = 0;
      float Ex_m = 0;
      float Ey_p = 0;
      float Ey_m = 0;

      float prev_x_p = fabs(pos[i - 1]);
      float prev_x_m = fabs(pos[i]);

      for (int j = 0; j < cnt; j++)
      {

        // positive movement (up)
        sendPosTarget(init_pos + mm2int(pos[i - 1]));
        sendCommand(go());
        getStatus();
        while ((((sts) >> (3)) & 0x01))
          // checkPanic();
          getStatus();

        sendCommand(disableDrive());

        delay(waitTime);
        float x_p = int2mm(getPosact() - init_pos);
        // unsigned long tik = millis();
        float y_p = getForce() - tare_force;

        if (j == 0)
        {
          k_p_p = x_p;
          k_f_p = y_p;
        }

        sum_pos_p += x_p;
        sum_p += y_p;
        Ex_p += x_p - k_p_p;
        Ey_p += y_p - k_f_p;
        sum_sq_pos_p += pow(x_p - k_p_p, 2);
        sum_sq_p += pow(y_p - k_f_p, 2);

        Serial.println("x_p: ");
        Serial.println(x_p, 6);
        Serial.println("Ex_p: ");
        Serial.println(Ex_p, 6);
        Serial.println("sum_sq_pos_p: ");
        Serial.println(sum_sq_pos_p, 6);

        Serial.write("check percent\n");

        getStatus();
        while (!(((sts) >> (0)) & 0x01))
        {
          getStatus();
          sendCommand(enableDrive());
        }

        sendPosTarget(init_pos);
        sendCommand(go());
        getStatus();
        while ((((sts) >> (3)) & 0x01))
          getStatus();

        // negative movement (down)
        sendPosTarget(init_pos + mm2int(pos[i]));
        sendCommand(go());
        getStatus();
        while ((((sts) >> (3)) & 0x01))
          // checkPanic();
          getStatus();
        sendCommand(disableDrive());
        delay(waitTime);
        float x_m = int2mm(getPosact() - init_pos);
        float y_m = getForce() - tare_force;

        if (j == 0)
        {
          k_p_m = x_m;
          k_f_m = y_m;
        }

        sum_pos_m += x_m;
        sum_m += y_m;
        Ex_m += x_m - k_p_m;
        Ey_m += y_m - k_f_m;
        sum_sq_pos_m += pow(x_m - k_p_m, 2);
        sum_sq_m += pow(y_m - k_f_m, 2);

        Serial.println("x_m: ");
        Serial.println(x_m, 6);
        Serial.println("Ex_m: ");
        Serial.println(Ex_m, 6);
        Serial.println("sum_sq_pos_m: ");
        Serial.println(sum_sq_pos_m, 6);

        Serial.write("check percent\n");

        getStatus();
        while (!(((sts) >> (0)) & 0x01))
        {
          getStatus();
          sendCommand(enableDrive());
        }

        sendPosTarget(init_pos);
        sendCommand(go());
        getStatus();
        while ((((sts) >> (3)) & 0x01))
          getStatus();

        // check to read consistent data
        if ((fabs(x_p) > 2 * prev_x_p || fabs(x_m) > 2 * prev_x_m))
        {
          // delete data from the cumulative quantities and redo the measure
          Serial.println("ErrorPos");
          sum_pos_p -= x_p;
          sum_p -= y_p;
          Ex_p -= x_p - k_p_p;
          Ey_p -= y_p - k_f_p;
          sum_sq_pos_p -= pow(x_p - k_p_p, 2);
          sum_sq_p -= pow(y_p - k_f_p, 2);

          sum_pos_m -= x_m;
          sum_m -= y_m;
          Ex_m -= x_m - k_p_m;
          Ey_m -= y_m - k_f_m;
          sum_sq_pos_m -= pow(x_m - k_p_m, 2);
          sum_sq_m -= pow(y_m - k_f_m, 2);
          j--;
        }

        delay(waitTime);
        float zero_val = getForce() - tare_force;
        float zero_pos = int2mm(getPosact() - init_pos);

        dtostrf(zero_val, 10, 6, zero_buff_force);
        dtostrf(zero_pos, 10, 6, zero_buff_pos);
        String tosend = "r " + msg_zero + zero_buff_force + " " + zero_buff_pos + "\n";
        Serial.println(tosend);
      }

      float meas_p = sum_p / cnt;
      float meas_m = sum_m / cnt;
      float pos_p = sum_pos_p / cnt;
      float pos_m = sum_pos_m / cnt;

      float var_f_p = 0;
      float var_f_m = 0;
      float var_pos_p = 0;
      float var_pos_m = 0;

      float std_f_p = 0;
      float std_f_m = 0;
      float std_pos_p = 0;
      float std_pos_m = 0;

      if (cnt > 1)
      {
        var_f_p = (sum_sq_p - pow(Ey_p, 2) / cnt) / (cnt - 1);
        var_f_m = (sum_sq_m - pow(Ey_m, 2) / cnt) / (cnt - 1);
        var_pos_p = (sum_sq_pos_p - pow(Ex_p, 2) / cnt) / (cnt - 1);
        var_pos_m = (sum_sq_pos_m - pow(Ex_m, 2) / cnt) / (cnt - 1);

        std_f_p = sqrtf(var_f_p);
        std_f_m = sqrtf(var_f_m);
        std_pos_p = sqrtf(var_pos_p);
        std_pos_m = sqrtf(var_pos_m);
      }

      //////////////////////////////////

      dtostrf(meas_p, 10, 6, num);
      Serial.println(msg + num);

      dtostrf(std_f_p, 10, 6, std1);
      dtostrf(std_pos_p, 10, 6, std2);
      Serial.println(msg_std + std1 + " " + std2);

      dtostrf(pos_p, 10, 6, num);
      Serial.println(msg_pos + num);

      //////////////////////////////////

      dtostrf(meas_m, 10, 6, num);
      Serial.println(msg + num);

      dtostrf(std_f_m, 10, 6, std1);
      dtostrf(std_pos_m, 10, 6, std2);
      Serial.println(msg_std + std1 + " " + std2);

      dtostrf(pos_m, 10, 6, num);
      Serial.println(msg_pos + num);

      sum_p = 0;
      sum_m = 0;
      sum_pos_p = 0;
      sum_pos_m = 0;
      sum_sq_p = 0;
      sum_sq_m = 0;
      sum_sq_pos_p = 0;
      sum_sq_pos_m = 0;
    }
    sendPosTarget(init_pos);
    sendCommand(go());
  }
}

void creepRoutine()
{
  String msg = "val ";
  String time_msg = "time_ax ";

  char num[15];
  char time_val[15];

  Serial.write("Creep Routine\n");
  flushSerial();
  Serial.write("send me\n");
  delay(100);

  float creep_displ = Serial.parseFloat(SKIP_WHITESPACE);
  float creep_period = Serial.parseFloat(SKIP_WHITESPACE);
  float creep_duration = Serial.parseFloat(SKIP_WHITESPACE);
  int num_creep = (int)(creep_duration * 1000 / creep_period);

  Serial.println(creep_displ);
  Serial.println(creep_period);
  Serial.println(creep_duration);

  Serial.write("Measuring\n");

  checkModbusConnection();
  setAccVelocity(creep_displ);

  sendPosTarget(init_pos + mm2int(creep_displ));
  sendCommand(go());
  getStatus();
  while ((((sts) >> (3)) & 0x01))
    // while (bitRead(sts_cllp, 2))
    getStatus();

  sendCommand(disableDrive());

  // float acquisitions[num_creep];
  // float time_axis[num_creep];

  float acquisitions;
  float time_axis;

  unsigned long tik = millis();
  // two separate loops, in order to obtain the measured value as istant as possible
  for (int i = 0; i < num_creep; i++)
  {
    acquisitions = getForce() - tare_force;
    unsigned long tok = millis();
    time_axis = float(tok - tik);
    dtostrf(acquisitions, 10, 6, num);
    Serial.println(msg + num);
    dtostrf(time_axis, 10, 6, time_val);
    Serial.println(time_msg + time_val);

    unsigned long to_wait = (unsigned long)(creep_period) - ((millis() - tik) % (int)creep_period);
    delay(to_wait);

    Serial.write("check percent\n");
    // Serial.println(acquisitions[i]);
    // Serial.println(time_axis[i]);
  }

  // for(int i=0; i<num_creep; i++){
  //   dtostrf(acquisitions[i], 10, 6, num);
  //   Serial.println(msg + num);
  //   delay(50);
  //   dtostrf(time_axis[i], 10, 6, time_val);
  //   Serial.println(time_msg + time_val);
  //   delay(50);
  // }

  getStatus();
  while (!(((sts) >> (0)) & 0x01))
  {
    getStatus();
    sendCommand(enableDrive());
  }

  sendPosTarget(init_pos);
  sendCommand(go());
  getStatus();
  while ((((sts) >> (3)) & 0x01))
    getStatus();
}

void getStatus()
{
  sts = modbusTCPClient.holdingRegisterRead(199 /* status flags*/);
  sts_cllp = modbusTCPClient.holdingRegisterRead(203 /* closed loop status flags*/);
}

void printStatus()
{
  if (modbusTCPClient.holdingRegisterRead(199 /* status flags*/) != -1)
  {
    Serial.println("\n\t Status: ");
    uint16_t this_sts = modbusTCPClient.holdingRegisterRead(199 /* status flags*/);
    if ((((this_sts) >> (0)) & 0x01))
      Serial.println("Azionamento abilitato");
    if ((((this_sts) >> (1)) & 0x01))
      Serial.println("Azionamento in allarme");
    if ((((this_sts) >> (2)) & 0x01))
      Serial.println("Quota motore sincronizzata");
    if ((((this_sts) >> (3)) & 0x01))
      Serial.println("Motore in movimento teorico");
    if ((((this_sts) >> (4)) & 0x01))
      Serial.println("Motore in accelerazione");
    if ((((this_sts) >> (5)) & 0x01))
      Serial.println("Motore a velocita' costante");
    if ((((this_sts) >> (6)) & 0x01))
      Serial.println("Motore in decelerazione");
    if ((((this_sts) >> (7)) & 0x01))
      Serial.println("Segnalazioni da registro Rstscllp");
    if ((((this_sts) >> (8)) & 0x01))
      Serial.println("Home terminato con errore");
    if ((((this_sts) >> (9)) & 0x01))
      Serial.println("Stato corrente: 1=CurON");
    if ((((this_sts) >> (10)) & 0x01))
      Serial.println("Motore in posizione");
    if ((((this_sts) >> (11)) & 0x01))
      Serial.println("Errore di inseguimento");
    if ((((this_sts) >> (12)) & 0x01))
      Serial.println("Motore mosso durante lo stato disable");
    if ((((this_sts) >> (13)) & 0x01))
      Serial.println("Verso rotazione antioraria");
    if ((((this_sts) >> (14)) & 0x01))
      Serial.println("Quota attuale fuori dai limiti software");
    if ((((this_sts) >> (15)) & 0x01))
      Serial.println("Home in corso");
    Serial.println("");
  }
}

void printAlarms()
{
  if (modbusTCPClient.holdingRegisterRead(227 /* alarms flags*/) != -1)
  {
    Serial.println("\n---------------");
    Serial.println("\t ALARMS: ");
    uint16_t alarm = modbusTCPClient.holdingRegisterRead(227 /* alarms flags*/);
    if ((((alarm) >> (0)) & 0x01))
      Serial.println("Overcurrent HW");
    if ((((alarm) >> (1)) & 0x01))
      Serial.println("Overcurrent SW");
    if ((((alarm) >> (2)) & 0x01))
      Serial.println("I2T");
    if ((((alarm) >> (3)) & 0x01))
      Serial.println("Errore di posizione");
    if ((((alarm) >> (4)) & 0x01))
      Serial.println("Errore di inseguimento");
    if ((((alarm) >> (5)) & 0x01))
      Serial.println("Overload digital output");
    if ((((alarm) >> (6)) & 0x01))
      Serial.println("Sovratemperatura");
    if ((((alarm) >> (7)) & 0x01))
      Serial.println("Sovratensione");
    if ((((alarm) >> (8)) & 0x01))
      Serial.println("Sottotensione");
    if ((((alarm) >> (9)) & 0x01))
      Serial.println("Errore fasatura encoder");
    if ((((alarm) >> (10)) & 0x01))
      Serial.println("Fase A motore disconessa");
    if ((((alarm) >> (11)) & 0x01))
      Serial.println("Fase B motore disconessa");
    if ((((alarm) >> (12)) & 0x01))
      Serial.println("Timeout Posizionamento");
    if ((((alarm) >> (13)) & 0x01))
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
  if (!(modbusTCPClient.holdingRegisterWrite(8 /* target position*/, splitted[0]) && modbusTCPClient.holdingRegisterWrite(8 /* target position*/ + 1, splitted[1])))
  {
    Serial.write("Errore nella scrittura della posizione\n");
  }
}

int32_t mm2int(float pos_mm)
{
  return int32_t(pos_mm * 2048 / 5);
}

float int2mm(int32_t pos_step)
{
  return float(pos_step) * 5 / 2048;
}

int32_t getPosact()
{
  int16_t lo = modbusTCPClient.holdingRegisterRead(0 /* actual position*/);
  int16_t hi = modbusTCPClient.holdingRegisterRead(0 /* actual position*/ + 1);
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
  int cnt = 1;
  if (mean_active)
  {
    if (fabs(val) <= th3)
      cnt = cnt_th3;
    if (fabs(val) <= th2)
      cnt = cnt_th2;
    if (fabs(val) <= th1)
      cnt = cnt_th1;
  }
  if (fabs(val) == zero_approx)
    cnt = cnt_zero;
  return cnt;
}

void setAccVelocity(float disp)
{
  if (vel_flag && !time_flag)
  {
    split32to16(int32_t(vel_max * 100));
    modbusTCPClient.holdingRegisterWrite(63 /* traslation speed*/, splitted[0]);
    modbusTCPClient.holdingRegisterWrite(63 /* traslation speed*/ + 1, splitted[1]);

    splitU32to16(uint32_t(acc_max) * 100);
    modbusTCPClient.holdingRegisterWrite(67 /* acceleration ramp*/, splitted[0]);
    modbusTCPClient.holdingRegisterWrite(67 /* acceleration ramp*/ + 1, splitted[1]);
    splitU32to16(uint32_t(acc_max) * 10);
    modbusTCPClient.holdingRegisterWrite(70 /* deceleration ramp*/, splitted[0]);
    modbusTCPClient.holdingRegisterWrite(70 /* deceleration ramp*/ + 1, splitted[1]);
  }
  if (!vel_flag && time_flag)
  {
    splitU32to16(uint32_t(5 * 100));
    modbusTCPClient.holdingRegisterWrite(67 /* acceleration ramp*/, splitted[0]);
    modbusTCPClient.holdingRegisterWrite(67 /* acceleration ramp*/ + 1, splitted[1]);
    splitU32to16(uint32_t(1 * 100));
    modbusTCPClient.holdingRegisterWrite(70 /* deceleration ramp*/, splitted[0]);
    modbusTCPClient.holdingRegisterWrite(70 /* deceleration ramp*/ + 1, splitted[1]);

    // vel [mm/s]
    float vel = fabs(disp) / (time_max * 5);
    vel = ((vel)<(-100)?(-100):((vel)>(100)?(100):(vel)));

    split32to16(int32_t(vel * 100));
    modbusTCPClient.holdingRegisterWrite(63 /* traslation speed*/, splitted[0]);
    modbusTCPClient.holdingRegisterWrite(63 /* traslation speed*/ + 1, splitted[1]);
  }
  else
  {
  }
}

void checkPanic()
{
  String panic_msg = "";
  if (Serial.available())
    panic_msg = Serial.readStringUntil("\n");
  Serial.println(panic_msg);
  if (panic_msg == "PANIC\n")
  {
    Serial.println("OPS");
    sendCommand(disableDrive());
  }
}

void sendMessage(String msg, float val1, float val2, float val3)
{
  char buff1[15];
  char buff2[15];
  char buff3[15];
  dtostrf(val1, 10, 6, buff1);
  msg += " ";
  msg += buff1;

  if (val2!=
# 1117 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino" 3 4
           __null
# 1117 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
               )
  {
    dtostrf(val2, 10, 6, buff2);
    msg += " ";
    msg += buff2;
  }
  if (val3!=
# 1123 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino" 3 4
           __null
# 1123 "C:\\Users\\stefa\\Documents\\Arduino\\ArduinoModbusThesis\\SMD1204_noLoop\\SMD1204_Functions.ino"
               )
  {
    dtostrf(val3, 10, 6, buff3);
    msg += " ";
    msg += buff3;
  }

  Serial.println(msg);
}
