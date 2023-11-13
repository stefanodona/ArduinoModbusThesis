float getForce()
{
  float force = 0;
  while (!loadcell.is_ready())
  {
  }
  // float val = loadcell.read_average(5);
  // float val = loadcell.read();
  float val = avg(5);
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
float getForce1(float x)
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