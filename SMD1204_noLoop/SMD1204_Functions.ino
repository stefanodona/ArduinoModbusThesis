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
  sendPosTarget((int32_t)0);

  // check status
  if (modbusTCPClient.holdingRegisterRead(Rstsflg) != -1)
  {
    sts = modbusTCPClient.holdingRegisterRead(Rstsflg);
  }

  // enable drive if disabled
  while (!bitRead(sts, 0))
  {
    sendCommand(enableDrive());
    getStatus();
  }

  // DEVICE ENABLED - SETTINGS HERE
  // Home Method
  split32to16(mm2int(0));
  modbusTCPClient.holdingRegisterWrite(Rhofs, splitted[0]);
  modbusTCPClient.holdingRegisterWrite(Rhofs + 1, splitted[1]);
  // modbusTCPClient.holdingRegisterWrite(Rhmode, (int16_t)(-9)); // in battuta indietro
  modbusTCPClient.holdingRegisterWrite(Rhmode, (int16_t)0); // azzeramento sul posto

  // velocity setting - rps*100
  split32to16(vel * 100);
  if (modbusTCPClient.holdingRegisterWrite(Rvel, splitted[0]) && modbusTCPClient.holdingRegisterWrite(Rvel + 1, splitted[1]))
  {
    Serial.print(F("Velocita' massima settata a: "));
    Serial.print(vel);
    Serial.println(" rps");
  }

  // setting acceleration ramp
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

void homingRoutine()
{
  // setting velocity to seek the tare position
  split32to16(vel_tare * 10);
  if (modbusTCPClient.holdingRegisterWrite(Rvel, splitted[0]) && modbusTCPClient.holdingRegisterWrite(Rvel + 1, splitted[1]))
  {
  }
  // seek the position in which the value of hx711 is equal to unclamped (in error band)
  sendCommand(home());

  Serial.write("Posizionare il centratore...\n");
  awaitKeyPressed();
  String inc_msg = Serial.readString();
  if (inc_msg != "ok\n")
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
  if (inc_msg != "ok\n")
  {
    flushSerial();
    Serial.flush();
    Serial.end();
    // return;
    resetFunc();
  }

  float clamped = getForce();
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
  // float disks_weight = (0.12995+0.1083+0.02543)*9.81;
  float disks_weight = (0.12995 + 0.1083 + 0.02027) * 9.81;
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

        checkArrival();
        delay(500);

        float post_moved = getForce();
        float diff = (post_moved - clamped) / pos;

        pos = ((tare - post_moved) / diff);
        pos = constrain(pos, -1.0, 1.0);

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

  sendCommand(home());

  getStatus();
  while (bitRead(sts, 15))
  {
    getStatus();
  }

  init_pos = getPosact();
  String msg = "tare ";
  sendMessage("tare", &tare_force, NULL, NULL);

  split32to16(vel * 100);
  if (modbusTCPClient.holdingRegisterWrite(Rvel, splitted[0]) && modbusTCPClient.holdingRegisterWrite(Rvel + 1, splitted[1]))
  {
  }

  search_active = false;
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

  char num[15];
  char zero_buff_pos[15];
  char zero_buff_force[15];
  char std1[15];
  char std2[15];

  Serial.write("Measuring\n");

  unsigned long tik = millis();
  unsigned long tok = 0;
  float tiktok = 0;

  // TIMING DIAGRAM
  //
  // pos              _____________
  //                 /|            |\
  //                / |            | \
  //               /  |            |  \
  //              /   |            |   \
  // ____________/    |            |    \___________-> time
  //            t_s  t_r          t_f  t_e

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
      // Measure start time
      tok = millis();
      tiktok = float(tok - tik);
      String t_start = "t_s";
      sendMessage(t_start, &tiktok, &pos[i], NULL);

      checkArrival();

      sendCommand(disableDrive());

      // Measure rise time
      tok = millis();
      tiktok = float(tok - tik);
      String t_rise = "t_r";
      sendMessage(t_rise, &tiktok, &pos[i], NULL);

      delay(waitTime);
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

      Serial.write("check percent\n");

      getStatus();
      while (!bitRead(sts, 0))
      {
        getStatus();
        sendCommand(enableDrive());
      }

      // Measure fall time
      tok = millis();
      tiktok = float(tok - tik);
      String t_fall = "t_f";
      sendMessage(t_fall, &tiktok, &pos[i], NULL);

      sendPosTarget(init_pos);
      sendCommand(go());

      checkArrival();

      // Measure end time
      tok = millis();
      tiktok = float(tok - tik);
      String t_end = "t_e";
      sendMessage(t_end, &tiktok, &pos[i], NULL);

      // negative movement (down)
      sendPosTarget(init_pos + mm2int(pos[i + 1]));
      sendCommand(go());
      // Measure start time
      tok = millis();
      tiktok = float(tok - tik);
      sendMessage(t_start, &tiktok, &pos[i + 1], NULL);

      checkArrival();

      sendCommand(disableDrive());

      // Measure rise time
      tok = millis();
      tiktok = float(tok - tik);
      // String t_rise = "t_r";
      sendMessage(t_rise, &tiktok, &pos[i + 1], NULL);

      delay(waitTime);
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

      Serial.write("check percent\n");

      getStatus();
      while (!bitRead(sts, 0))
      {
        getStatus();
        sendCommand(enableDrive());
      }

      // Measure fall time
      tok = millis();
      tiktok = float(tok - tik);
      // String t_fall = "t_f";
      sendMessage(t_fall, &tiktok, &pos[i + 1], NULL);

      sendPosTarget(init_pos);
      sendCommand(go());

      checkArrival();

      // Measure end time
      tok = millis();
      tiktok = float(tok - tik);
      sendMessage(t_end, &tiktok, &pos[i + 1], NULL);

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
        // Measure start time
        tok = millis();
        tiktok = float(tok - tik);
        String t_start = "t_s";
        sendMessage(t_start, &tiktok, &pos[i - 1], NULL);

        checkArrival();

        sendCommand(disableDrive());

        // Measure rise time
        tok = millis();
        tiktok = float(tok - tik);
        String t_rise = "t_r";
        sendMessage(t_rise, &tiktok, &pos[i - 1], NULL);

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

        Serial.write("check percent\n");

        getStatus();
        while (!bitRead(sts, 0))
        {
          getStatus();
          sendCommand(enableDrive());
        }

        // Measure fall time
        tok = millis();
        tiktok = float(tok - tik);
        String t_fall = "t_f";
        sendMessage(t_fall, &tiktok, &pos[i - 1], NULL);

        sendPosTarget(init_pos);
        sendCommand(go());

        checkArrival();

        // Measure end time
        tok = millis();
        tiktok = float(tok - tik);
        String t_end = "t_e";
        sendMessage(t_end, &tiktok, &pos[i - 1], NULL);

        // negative movement (down)
        sendPosTarget(init_pos + mm2int(pos[i]));
        sendCommand(go());
        // Measure start time
        tok = millis();
        tiktok = float(tok - tik);
        sendMessage(t_start, &tiktok, &pos[i], NULL);

        checkArrival();

        sendCommand(disableDrive());

        // Measure rise time
        tok = millis();
        tiktok = float(tok - tik);
        // String t_rise = "t_r";
        sendMessage(t_rise, &tiktok, &pos[i], NULL);

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

        Serial.write("check percent\n");

        getStatus();
        while (!bitRead(sts, 0))
        {
          getStatus();
          sendCommand(enableDrive());
        }

        // Measure fall time
        tok = millis();
        tiktok = float(tok - tik);
        // String t_fall = "t_f";
        sendMessage(t_fall, &tiktok, &pos[i], NULL);

        sendPosTarget(init_pos);
        sendCommand(go());

        checkArrival();

        // Measure end time
        tok = millis();
        tiktok = float(tok - tik);
        sendMessage(t_end, &tiktok, &pos[i], NULL);

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

void trackingRoutine()
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

  Serial.write("Measuring\n");

  unsigned long tik = millis();
  unsigned long tok = 0;
  unsigned long tiktok = 0;
  // unsigned long to_wait = 0;

  int num_cyc = (int)(waitTime / 100); // stop time / min time of measurement

  // String t_track = "t_track";

  Serial.write("andata\n");
  for (int i = 0; i < num_pos; i = i + 2)
  {
    int cnt = getAvgCnt(pos[i]);
    checkModbusConnection();
    setAccVelocity(pos[i]);

    Serial.println("cnt ");
    Serial.println(cnt);

    // positive movement (up)
    sendPosTarget(init_pos + mm2int(pos[i]));
    sendCommand(go());

    checkArrival();

    sendCommand(disableDrive());

    // Measure rise time

    // for (int j = 0; j < num_cyc; j++)
    // {
    //   tok = millis();
    //   tiktok = tok - tik;
    //   // Measure position and force
    //   float x_p = int2mm(getPosact() - init_pos);
    //   float y_p = getForce() - tare_force;

    //   sendMessage(t_track, x_p, y_p, float(tiktok));

    //   to_wait = (unsigned long)(100) - ((millis() - tok) % (int)100);
    //   delay(to_wait);
    // }

    measurePosForceTime(tik, num_cyc, pos[i]);

    Serial.write("check percent\n");

    getStatus();
    while (!bitRead(sts, 0))
    {
      getStatus();
      sendCommand(enableDrive());
    }

    sendPosTarget(init_pos);
    sendCommand(go());

    checkArrival();

    // negative movement (down)
    sendPosTarget(init_pos + mm2int(pos[i + 1]));
    sendCommand(go());

    checkArrival();

    sendCommand(disableDrive());

    measurePosForceTime(tik, num_cyc, pos[i + 1]);
    // for (int j = 0; j < num_cyc; j++)
    // {
    //   tok = millis();
    //   tiktok = tok - tik;
    //   // Measure position and force
    //   float x_p = int2mm(getPosact() - init_pos);
    //   float y_p = getForce() - tare_force;

    //   sendMessage(t_track, x_p, y_p, float(tiktok));

    //   to_wait = (unsigned long)(100) - ((millis() - tok) % (int)100);
    //   delay(to_wait);
    // }

    getStatus();
    while (!bitRead(sts, 0))
    {
      getStatus();
      sendCommand(enableDrive());
    }

    sendPosTarget(init_pos);
    sendCommand(go());

    checkArrival();

    measurePosForceTime(tik, num_cyc, int2mm(init_pos));
    // for (int j = 0; j < num_cyc; j++)
    // {
    //   tok = millis();
    //   tiktok = tok - tik;
    //   // Measure position and force
    //   float x_p = int2mm(getPosact() - init_pos);
    //   float y_p = getForce() - tare_force;

    //   sendMessage(t_track, x_p, y_p, float(tiktok));

    //   to_wait = (unsigned long)(100) - ((millis() - tok) % (int)100);
    //   delay(to_wait);
    // }
  }

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

      // positive movement (up)
      sendPosTarget(init_pos + mm2int(pos[i - 1]));
      sendCommand(go());
      // Measure start time
      tok = millis();
      tiktok = tok - tik;

      checkArrival();

      sendCommand(disableDrive());

      // Measure rise time

      measurePosForceTime(tik, num_cyc, pos[i - 1]);

      // for (int j = 0; j < num_cyc; j++)
      // {
      //   tok = millis();
      //   tiktok = tok - tik;
      //   // Measure position and force
      //   float x_p = int2mm(getPosact() - init_pos);
      //   float y_p = getForce() - tare_force;

      //   sendMessage(t_track, x_p, y_p, float(tiktok));

      //   to_wait = (unsigned long)(100) - ((millis() - tok) % (int)100);
      //   delay(to_wait);
      // }

      Serial.write("check percent\n");

      getStatus();
      while (!bitRead(sts, 0))
      {
        getStatus();
        sendCommand(enableDrive());
      }

      sendPosTarget(init_pos);
      sendCommand(go());

      checkArrival();

      // negative movement (down)
      sendPosTarget(init_pos + mm2int(pos[i]));
      sendCommand(go());

      checkArrival();

      sendCommand(disableDrive());

      measurePosForceTime(tik, num_cyc, pos[i]);

      // for (int j = 0; j < num_cyc; j++)
      // {
      //   tok = millis();
      //   tiktok = tok - tik;
      //   // Measure position and force
      //   float x_p = int2mm(getPosact() - init_pos);
      //   float y_p = getForce() - tare_force;

      //   sendMessage(t_track, x_p, y_p, float(tiktok));

      //   to_wait = (unsigned long)(100) - ((millis() - tok) % (int)100);
      //   delay(to_wait);
      // }

      getStatus();
      while (!bitRead(sts, 0))
      {
        getStatus();
        sendCommand(enableDrive());
      }

      sendPosTarget(init_pos);
      sendCommand(go());

      checkArrival();

      measurePosForceTime(tik, num_cyc, int2mm(init_pos));

      // for (int j = 0; j < num_cyc; j++)
      // {
      //   tok = millis();
      //   tiktok = tok - tik;
      //   // Measure position and force
      //   float x_p = int2mm(getPosact() - init_pos);
      //   float y_p = getForce() - tare_force;

      //   sendMessage(t_track, x_p, y_p, float(tiktok));

      //   to_wait = (unsigned long)(100) - ((millis() - tok) % (int)100);
      //   delay(to_wait);
      // }
    }
    sendPosTarget(init_pos);
    sendCommand(go());
  }
}

void creepRoutine()
{
  String msg = "val ";
  String time_msg = "time_ax ";

  char num[20];
  char time_val[20];

  Serial.write("Creep Routine\n");
  flushSerial();
  Serial.write("send me\n");
  delay(100);

  float creep_displ = Serial.parseFloat(SKIP_WHITESPACE);
  float creep_period = Serial.parseFloat(SKIP_WHITESPACE);
  float creep_duration = Serial.parseFloat(SKIP_WHITESPACE);
  // uint64_t num_creep = (uint64_t)round(creep_duration * 1000 / creep_period);
  unsigned long num_creep = round(creep_duration * 1000 / creep_period);

  // Serial.println("Num creep");
  // Serial.println(num_creep);

  // return;

  // Serial.println(creep_displ);
  // Serial.println(creep_period);
  // Serial.println(creep_duration);

  Serial.write("Measuring\n");

  checkModbusConnection();
  setAccVelocity(creep_displ);

  sendPosTarget(init_pos + mm2int(creep_displ));
  sendCommand(go());

  checkArrival();

  sendCommand(disableDrive());

  float acquisitions;
  float time_axis;

  unsigned long tik = millis();
  // two separate loops, in order to obtain the measured value as istant as possible
  for (unsigned long i = 0; i < num_creep; i++)
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
    Serial.flush();
  }

  checkModbusConnection();
  sendCommand(enableDrive());
  getStatus();
  while (!bitRead(sts, 0))
  {
    getStatus();
    sendCommand(enableDrive());
  }

  sendPosTarget(init_pos);
  sendCommand(go());

  checkArrival();
}

void getStatus()
{
  sts = modbusTCPClient.holdingRegisterRead(Rstsflg);
  sts_cllp = modbusTCPClient.holdingRegisterRead(Rstscllp);
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

float int2mm(int32_t pos_step)
{
  return float(pos_step) * 5 / 2048;
}

int32_t getPosact()
{
  int16_t lo = modbusTCPClient.holdingRegisterRead(Rposact);
  int16_t hi = modbusTCPClient.holdingRegisterRead(Rposact + 1);
  int32_t data = hi;
  data = (data << 16) | lo;
  return data;
}

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
    modbusTCPClient.holdingRegisterWrite(Rvel, splitted[0]);
    modbusTCPClient.holdingRegisterWrite(Rvel + 1, splitted[1]);

    splitU32to16(uint32_t(acc_max) * 100);
    modbusTCPClient.holdingRegisterWrite(Racc, splitted[0]);
    modbusTCPClient.holdingRegisterWrite(Racc + 1, splitted[1]);
    splitU32to16(uint32_t(acc_max) * 10);
    modbusTCPClient.holdingRegisterWrite(Rdec, splitted[0]);
    modbusTCPClient.holdingRegisterWrite(Rdec + 1, splitted[1]);
  }
  if (!vel_flag && time_flag)
  {
    splitU32to16(uint32_t(5 * 100));
    modbusTCPClient.holdingRegisterWrite(Racc, splitted[0]);
    modbusTCPClient.holdingRegisterWrite(Racc + 1, splitted[1]);
    splitU32to16(uint32_t(1 * 100));
    modbusTCPClient.holdingRegisterWrite(Rdec, splitted[0]);
    modbusTCPClient.holdingRegisterWrite(Rdec + 1, splitted[1]);

    // vel [mm/s]
    float vel = fabs(disp) / (time_max * 5);
    vel = constrain(vel, -100, 100);

    split32to16(int32_t(vel * 100));
    modbusTCPClient.holdingRegisterWrite(Rvel, splitted[0]);
    modbusTCPClient.holdingRegisterWrite(Rvel + 1, splitted[1]);
  }
  else
  {
  }
}

void sendMessage(String msg, float *val1, float *val2, float *val3)
{
  char buff1[15];
  char buff2[15];
  char buff3[15];
  dtostrf(*val1, 10, 6, buff1);
  msg += " ";
  msg += buff1;

  if (val2 != NULL)
  {
    dtostrf(*val2, 10, 6, buff2);
    msg += " ";
    msg += buff2;
  }
  if (val3 != NULL)
  {
    dtostrf(*val3, 10, 6, buff3);
    msg += " ";
    msg += buff3;
  }

  Serial.println(msg);
}

void measurePosForceTime(unsigned long tik, int num_cyc, float x_p)
{
  String t_track = "t_track";
  unsigned long tok;
  float tiktok;
  int period = 100;
  // unsigned long to_wait = 0;
  unsigned long tak = millis();
  for (int j = 0; j < num_cyc; j++)
  {
    // Measure position and force
    unsigned long tek = millis();
    // float x_p = int2mm(getPosact() - init_pos);

    float y_p = getForce() - tare_force;
    tok = millis();
    tiktok = float(tok - tik);

    Serial.println("measure time:");
    Serial.println(tok - tek);

    unsigned long to_wait = (unsigned long)(period) - ((millis() - tak) % period);
    // Serial.println("towait:");
    // Serial.println(to_wait);
    delay(to_wait);
    sendMessage(t_track, &x_p, &y_p, &tiktok);
  }
}

void checkArrival()
{
  getStatus();
  while (!bitRead(sts, 10))
    getStatus();
}