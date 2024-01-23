void selectLoadcell()
{
  bool valid = false;
  while (!valid)
  {
    Serial.println("Inserire fondoscala della cella di carico [kg]...");
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