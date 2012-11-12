int wrap(int value, int from, int to)
{
  int d = to - from + 1;
  if (value < from)
  {
    for (; value < from; value += d);
  }
  if (value > to)
  {
    for (; value > to; value -= d);
  }
  return value;
}

float bearing(float x, float y)
{
  return FastMath.atan2(y,x);
}

/**
 * @param x [0, width)
 * @param y [0, height)
 * @param distance in Rad
 * @param bearing [0, 2*PI)
 * @return destination in (x, y)
 */
PVector dest(float x, float y, float distance, float bearing)
{
  float lat0 = (float)(y/height*Math.PI-Math.PI/2);
  float lon0 = (float)(x/width*2*Math.PI);
  float lat1 = FastMath.asin(sin(lat0)*cos(distance) + cos(lat0)*sin(distance)*cos(bearing));
  float lon1 = lon0 + FastMath.atan2(sin(distance)*sin(bearing), cos(distance)*cos(lat0)
    - cos(bearing)*sin(distance)*sin(lat0));
  return new PVector((float)(width * lon1/(2 * Math.PI)), (float)(height* (lat1+Math.PI/2)/(Math.PI)));
}

float distSq(float x0, float y0, float x1, float y1)
{
  return sq(x0-x1)+sq(y1-y0);
}

float wrapDistSq(float x0, float y0, float x1, float y1)
{
  float d0 = distSq(x0, y0, x1, y1);
  if (d0 < width/2)
  {
    return d0;
  }
  float d1 = distSq(x0+width, y0, x1, y1);
  if (d1 < width/2)
  {
    return min(d0, d1);
  }
  float d2 = distSq(x0-width, y0, x1, y1);
  return min(min(d0, d1), d2);
}

public static double fastpow(final double a, final double b)
{
    final long tmp = Double.doubleToLongBits(a);
    final long tmp2 = (long)(b * (tmp - 4606921280493453312L)) + 4606921280493453312L;
    return Double.longBitsToDouble(tmp2);
}
  
// http://en.wikipedia.org/wiki/Poisson_distribution#Generating_Poisson-distributed_random_variables
public static double poissonRandom(float expectedValue)
{
  float l = (float)fastpow(Math.E, -expectedValue);
  int k = 0;
  float p = 1;
  do
  {
    k++;
    p*=Math.random();
  }
  while (p > l);
  return k - 1;
}


float[][] world = null;
float tmpWorld[][] = null;

class Plate
{
  List<PVector> pos;
  float vx, vy;
  color c;
  
  Plate(List<PVector> pos, float vx, float vy, color c)
  {
    this.pos = pos;
    this.vx = vx;
    this.vy = vy;
    this.c = c;
  }
  
  float distanceSq(final PVector p)
  {
    float d = Float.MAX_VALUE;
    for (PVector pi : pos)
    {
      float di = wrapDistSq(pi.x, pi.y, p.x, p.y);
      if (di < d)
      {
        d = di;
      }
    }
    return d;
  }
  
  color getColor()
  {
    return c;
  }
  
  List<PVector> getPos()
  {
    return pos;
  }
  float getVx()
  {
    return vx;
  }
  float getVy()
  {
    return vy;
  }
}

List<Plate> plates = new ArrayList<Plate>();

Plate getNearestPlate(float x, float y)
{
  PVector pos = new PVector(x, y);
  // closest plate found so far.
  Plate r = null;
  float d = Float.MAX_VALUE;
  for (Plate p : plates)
  {
    if (r == null)
    {
      r = plates.get(0);
      d = r.distanceSq(pos);
    }
    if (p.distanceSq(pos) < d)
    {
      r = p;
      d = p.distanceSq(pos);
    }
  }
  return r;
}

void step(float dt)
{
  println("Step");
  
  for (int i = 0; i < width; i++)
  {
    for (int j = 0; j < height; j++)
    {
      final Plate p = getNearestPlate(i, j);
      float h = world[i][j];
      PVector d = dest(i, j, (float)(dt*dist(0, 0, p.getVx(), p.getVy())/width * 2 * Math.PI), bearing(p.getVx(), p.getVy()));
      //d = new PVector(i+p.getVx()*dt, j+p.getVy()*dt);
      int u = wrap((int) d.x, 0, width-1);
      int v = wrap((int) d.y, 0, height-1);

      if (tmpWorld[u][v] == 0)
      {
        tmpWorld[u][v] += world[i][j];
      }
      else
      {
        PVector pv = null;
        float cp = Float.MAX_VALUE;
        for (int l = 5; l > 0; l--)
        {
          float r = (float)(width/200*poissonRandom(5));
          float theta = random(0, (float) (2 * Math.PI));
          PVector rd = dest(i, j, dt * r, theta);
          int ru = wrap((int) rd.x, 0, width-1);
          int rv = wrap((int) rd.y, 0, height-1);
          float c = sq(world[ru][rv])*(sqrt(wrapDistSq(i, j, ru, rv)) + 1) / 10;
          if (c < cp)
          {
            cp = c;
            pv = new PVector(ru, rv);
          }
        }
        int pvx = (int) pv.x;
        int pvy = (int) pv.y;
        tmpWorld[pvx][pvy] += world[i][j];
      }
      
      world[i][j] = 0;
    }
  }
  
  
  float noiseScale = 0.044;
  for (int i = 0; i < width; i++)
  {
    for (int j = 0; j < height; j++)
    {
      // rift?
      if (tmpWorld[i][j] == 0)
      {
        tmpWorld[i][j] = 140*noise(i*noiseScale, j*noiseScale);
      }
      world[i][j] += (tmpWorld[i][j]
        + tmpWorld[wrap(i+1, 0, width-1)][j]
        + tmpWorld[wrap(i-1, 0, width-1)][j]
        + tmpWorld[i][wrap(j+1, 0, height-1)]
        + tmpWorld[i][wrap(j-1, 0, height-1)]
        + tmpWorld[wrap(i+1, 0, width-1)][wrap(j+1, 0, height-1)]
        + tmpWorld[wrap(i+1, 0, width-1)][wrap(j-1, 0, height-1)]
        + tmpWorld[wrap(i-1, 0, width-1)][wrap(j+1, 0, height-1)]
        + tmpWorld[wrap(i-1, 0, width-1)][wrap(j-1, 0, height-1)])/9;
    }
  }
  for (int i = 0; i < width; i++)
  {
    for (int j = 0; j < height; j++)
    {
      tmpWorld[i][j] = 0;
    }
  }
}

void setup()
{
  size(800, 400);
  background(0);
  
  world = new float[width][height];
  tmpWorld = new float[width][height];
  
  float noiseScale = 0.022;
  for (int i = 0; i < width; i++)
  {
    for (int j = 0; j < height; j++)
    {
      world[i][j] = 20*noise(i*noiseScale, j*noiseScale)+60;
    }
  }
  colorMode(HSB);
  for (int n = 0; n < 20; n++)
  {
    float v = random(0, 1);
    float x = random(0, width-1);
    float y = random(0, height-1);
    float theta = random(0, 2*PI);
    float vx = v * cos(theta);
    float vy = v * sin(theta);
    
    // don't put a place near edges
    if (x < width/10 && x > width-width/10 && y < height/10 && y > height-height/10)
    {
      n--;
      continue;
    }
    
    Plate p = getNearestPlate(x, y);
    if (p != null)
    {
      float d = sqrt(p.distanceSq(new PVector(x, y)));
      if (d < width/8)
      {
        n--;
        continue;
      }
    }
    println("add parent plate at x:"+x+" y:"+y+" vx:"+vx+" vy:"+vy);
    List<PVector> pos = new ArrayList<PVector>();
    pos.add(new PVector(x, y));
    color c = color(random(0, 255), 255, 200);
    plates.add(new Plate(pos, vx, vy, c));
  }
  colorMode(RGB);
  for (Plate p : plates)
  {
    float x = p.getPos().get(0).x;
    float y = p.getPos().get(0).y;
    float vx = p.getVx();
    float vy = p.getVy();
    for (int i = 0; i < 20; i++)
    {
      double r = width/120 * poissonRandom(8);
      float t = random(0, (float)(2 * Math.PI));
      float px = wrap((int) (r*cos(t)+x), 0, width-1);
      float py = wrap((int) (r*sin(t)+y), 0, height-1);
      println("add plate pos at x:"+px+" y:"+py+" vx:"+vx+" vy:"+vy);
      List<PVector> pos = p.getPos();
      pos.add(new PVector(px, py));
    }
  }
}

void draw()
{
  loadPixels();
  for (int i = 0; i < width; i++)
  {
    for (int j = 0; j < height; j++)
    {
      color c = color(world[i][j], world[i][j], world[i][j]);
      if (world[i][j] < 80)
      {
        pixels[j*width+i] = blendColor(c, color(90, 120, 250), BURN);
      }
      else
      {
        pixels[j*width+i] = blendColor(c, color(10, 100, 20), SCREEN);
      }
    }
  }
  updatePixels();
  /*for (Plate p : plates)
  {
    fill(p.getColor());
    for (PVector pos : p.getPos())
    {
      ellipse((int)pos.x, (int)pos.y, 3, 3);
    }
  }*/
  step(0.01);
}
