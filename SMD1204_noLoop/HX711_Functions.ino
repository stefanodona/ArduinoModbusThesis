float getForce()
{
  float force = 0;
  // while (!loadcell.is_ready())
  // {
  // }
  float val=0;
  // if (stat_creep_flag || tracking_flag) val = loadcell.read();
  // else val = loadcell.read_average(5);
  if (!search_active)
    val = loadcell.read();
  else
    val = loadcell.read_average(5);
  // float val = avg(5);
  switch (FULLSCALE)
  {
  // case 1:
  //   force = getForce1(val);
  //   break;
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
// float getForce1(float x)
// {
//   // FIXME: insert the right ones
//   float a = 2.35491e-08;
//   float b = 0.0237357;
//   float c = -0.442871;
//   float force = a * x * x + b * x + c;
//   return force;
// }

float getForce3(float x)
{
  float a = 0;
  float b = 7.540505 * pow(10, -6);
  float c = -2.664501 * pow(10, -3);
  float force = a * x * x + b * x + c;
  return force;
  // return x;
}

float getForce10(float x)
{
  float a = 0;
  // float b = 7.540505 * pow(10, -6) * 10 / 3; // vecchio
  // float b = 2.708316*pow(10, -5);
  float b = 2.701535 * pow(10, -5);
  float c = 0;
  float force = a * x * x + b * x + c;
  return force;
}

float getForce50(float x)
{
  float a = 0;
  float b = 1.100365 * pow(10, -4);
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