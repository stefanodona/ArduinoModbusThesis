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
    Serial.print("Velocita' massima settata a: ");
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

        while (bitRead(sts, 3))
        {
          getStatus();
        }
        delay(500);

        float post_moved = getForce();
        float diff = (post_moved - clamped) / pos;

        pos = ((tare - post_moved) / diff);
        pos = constrain(pos, -1.0, 1.0);

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
  while (bitRead(sts, 15))
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

  sendMessage("tare", tare_force, NULL, NULL);

  split32to16(vel * 100);
  if (modbusTCPClient.holdingRegisterWrite(Rvel, splitted[0]) && modbusTCPClient.holdingRegisterWrite(Rvel + 1, splitted[1]))
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
      tok=millis();
      tiktok = tok-tik;
      String t_start = "t_s";
      sendMessage(t_start, float(tiktok), pos[i], NULL);

      getStatus();
      while (bitRead(sts, 3))
        // checkPanic();
        getStatus();
      

      sendCommand(disableDrive());


      // Measure rise time
      tok=millis();
      tiktok = tok-tik;
      String t_rise = "t_r";
      sendMessage(t_rise, float(tiktok), pos[i], NULL);

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
      while (!bitRead(sts, 0))
      {
        getStatus();
        sendCommand(enableDrive());
      }

      // Measure fall time
      tok=millis();
      tiktok = tok-tik;
      String t_fall = "t_f";
      sendMessage(t_fall, float(tiktok), pos[i], NULL);

      sendPosTarget(init_pos);
      sendCommand(go());
      getStatus();
      while (bitRead(sts, 3))
        getStatus();

      // Measure end time
      tok=millis();
      tiktok = tok-tik;
      String t_end = "t_e";
      sendMessage(t_end, float(tiktok), pos[i], NULL);

      // negative movement (down)
      sendPosTarget(init_pos + mm2int(pos[i + 1]));
      sendCommand(go());
      // Measure start time
      tok=millis();
      tiktok = tok-tik;
      sendMessage(t_start, float(tiktok), pos[i], NULL);
     
      getStatus();
      while (bitRead(sts, 3))
        // checkPanic();
        getStatus();
      
      
      sendCommand(disableDrive());

      // Measure rise time
      tok=millis();
      tiktok = tok-tik;
      // String t_rise = "t_r";
      sendMessage(t_rise, float(tiktok), pos[i+1], NULL);

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

      Serial.println("x_m: ");
      Serial.println(x_m, 6);
      Serial.println("Ex_m: ");
      Serial.println(Ex_m, 6);
      Serial.println("sum_sq_pos_m: ");
      Serial.println(sum_sq_pos_m, 6);

      Serial.write("check percent\n");

      getStatus();
      while (!bitRead(sts, 0))
      {
        getStatus();
        sendCommand(enableDrive());
      }

      // Measure rise time
      tok=millis();
      tiktok = tok-tik;
      // String t_fall = "t_f";
      sendMessage(t_fall, float(tiktok), pos[i+1], NULL);

      sendPosTarget(init_pos);
      sendCommand(go());
      getStatus();
      while (bitRead(sts, 3))
        getStatus();
      
      // Measure end time
      tok=millis();
      tiktok = tok-tik;
      sendMessage(t_end, float(tiktok), pos[i], NULL);

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
        while (bitRead(sts, 3))
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
        while (!bitRead(sts, 0))
        {
          getStatus();
          sendCommand(enableDrive());
        }

        sendPosTarget(init_pos);
        sendCommand(go());
        getStatus();
        while (bitRead(sts, 3))
          getStatus();

        // negative movement (down)
        sendPosTarget(init_pos + mm2int(pos[i]));
        sendCommand(go());
        getStatus();
        while (bitRead(sts, 3))
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
        while (!bitRead(sts, 0))
        {
          getStatus();
          sendCommand(enableDrive());
        }

        sendPosTarget(init_pos);
        sendCommand(go());
        getStatus();
        while (bitRead(sts, 3))
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
  while (bitRead(sts, 3))
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
  while (!bitRead(sts, 0))
  {
    getStatus();
    sendCommand(enableDrive());
  }

  sendPosTarget(init_pos);
  sendCommand(go());
  getStatus();
  while (bitRead(sts, 3))
    getStatus();
}

void getStatus()
{
  sts = modbusTCPClient.holdingRegisterRead(Rstsflg);
  sts_cllp = modbusTCPClient.holdingRegisterRead(Rstscllp);
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

  if (val2!=NULL)
  {
    dtostrf(val2, 10, 6, buff2);
    msg += " ";
    msg += buff2;
  }
  if (val3!=NULL)
  {
    dtostrf(val3, 10, 6, buff3);
    msg += " ";
    msg += buff3;
  }

  Serial.println(msg);
}
