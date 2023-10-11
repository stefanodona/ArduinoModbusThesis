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
    modbusTCPClient.holdingRegisterWrite(Rhmode, int16_t(0)); // in battuta indietro

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

  populatePosArray();

  Serial.println("\nSi desidera mediare i piccoli spostamenti? S/N");
  awaitKeyPressed();
  int ans = Serial.read();
  if (isUpperCase(ans))
    ans = tolower(ans);
  switch (char(ans))
  {
  case 'n':
    mean_active = false;
    break;
  default:
    mean_active = true;
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
  PHASE = MEASUREMENT;
}

// TODO: create routine
void measureRoutine()
{
  // measuring
  // intially we'll develop a routine that will move-stop-measure-move-stop-measure and so on
  getStatus();

  target = 20; // [mm]
  // engine in position
  if (bitRead(sts, 10))
  {
    sendPosTarget(mm2int(target));
    Serial.print("POSTARG: ");
    Serial.println(mm2int(target));
    sendCommand(go());
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
    uint16_t sts = modbusTCPClient.holdingRegisterRead(Rstsflg);
    if (bitRead(sts, 0))
      Serial.println("Azionamento abilitato");
    if (bitRead(sts, 1))
      Serial.println("Azionamento in allarme");
    if (bitRead(sts, 2))
      Serial.println("Quota motore sincronizzata");
    if (bitRead(sts, 3))
      Serial.println("Motore in movimento teorico");
    if (bitRead(sts, 4))
      Serial.println("Motore in accelerazione");
    if (bitRead(sts, 5))
      Serial.println("Motore a velocita’ costante");
    if (bitRead(sts, 6))
      Serial.println("Motore in decelerazione");
    if (bitRead(sts, 7))
      Serial.println("Segnalazioni da registro Rstscllp");
    if (bitRead(sts, 8))
      Serial.println("Home terminato con errore");
    if (bitRead(sts, 9))
      Serial.println("Stato corrente: 1=CurON");
    if (bitRead(sts, 10))
      Serial.println("Motore in posizione");
    if (bitRead(sts, 11))
      Serial.println("Errore di inseguimento");
    if (bitRead(sts, 12))
      Serial.println("Motore mosso durante lo stato disable");
    if (bitRead(sts, 13))
      Serial.println("Verso rotazione antioraria");
    if (bitRead(sts, 14))
      Serial.println("Quota attuale fuori dai limiti software");
    if (bitRead(sts, 15))
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
  meas_pos = (float *)malloc(num_pos);
  for (int i = 0; i < num_pos; i++)
  {
    meas_pos[i] = min_pos + mesh_size * i;
    Serial.print(meas_pos[i]);
    Serial.print(" ");
  }
  Serial.print("\n");
}
