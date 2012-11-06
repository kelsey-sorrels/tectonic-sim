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

class Plate
{
  List<PVector> pos;
  float vx, vy;
  
  Plate(List<PVector> pos, float vx, float vy)
  {
    this.pos = pos;
    this.vx = vx;
    this.vy = vy;
  }
  
  float distance(final PVector p)
  {
    float d = Float.MAX_VALUE;
    for (PVector pi : pos)
    {
      float di = dist(pi.x, pi.y, p.x, p.y);
      if (di < d)
      {
        d = di;
      }
    }
    return d;
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
  Plate r = plates.get(0);
  for (Plate p : plates)
  {
    if (p.distance(pos) < r.distance(pos))
    {
      r = p;
    }
  }
  return r;
}

void step(float dt)
{
  float tmpWorld[][] = new float[width][height];
  
  for (int i = 0; i < width; i++)
  {
    for (int j = 0; j < height; j++)
    {
      final Plate p = getNearestPlate(i, j);
      float h = world[i][j];
      
      int u = wrap((int)(i+p.getVx()*dt), 0, width-1);
      int v = wrap((int)(j+p.getVy()*dt), 0, height-1);

      if (tmpWorld[u][v] == 0)
      {
        tmpWorld[u][v] += world[i][j];
      }
      else
      {
        PVector pv = null;
        float cp = Float.MAX_VALUE;
        for (int l = 20; l > 0; l--)
        {
          int r = 10;
          int ru = wrap((int) (random(-r, r) + u) , 0, width-1);
          int rv = wrap((int) (random(-r, r) + v), 0, height-1);
          float d = (dist(i, j, ru, rv) + 1) / 10;
          float c = sq(world[ru][rv])*d;
          if (c < cp)
          {
            cp = c;
            pv = new PVector(ru, rv);
          }
        }
        int pvx = (int) pv.x;
        int pvy = (int) pv.y;
        tmpWorld[pvx][pvy] += world[i][j]/5;
        tmpWorld[wrap(pvx+1, 0, width-1)][wrap(pvy, 0, height-1)] += world[i][j]/5;
        tmpWorld[wrap(pvx-1, 0, width-1)][wrap(pvy, 0, height-1)] += world[i][j]/5;
        tmpWorld[wrap(pvx, 0, width-1)][wrap(pvy+1, 0, height-1)] += world[i][j]/5;
        tmpWorld[wrap(pvx, 0, width-1)][wrap(pvy-1, 0, height-1)] += world[i][j]/5;
      }
      
      world[i][j] = 0;
    }
  }
  
  for (int i = 0; i < width; i++)
  {
    for (int j = 0; j < height; j++)
    {
      world[i][j] += tmpWorld[i][j];
      continue;
      // rift?
      /*if (world[i][j] == 0)
      {
        try
        {
          world[i][j] = (
              world[(i+1)%width][j]
            + world[(i-1)%width][j]
            + world[i][(j+1)%height]
            + world[i][(j-1)%height])/4;
        }
        catch(ArrayIndexOutOfBoundsException e)
        {
        }
      }
      if (world[i][j] > 255)
      {
        float e = random (0, world[i][j]-255);
        try
        {
          world[(i+(int)random(-5,5))%width][(j+(int)random(-5, 5))%height]  += e;
          world[i][j] -= e;
        }
        catch(ArrayIndexOutOfBoundsException ex)
        {
        }
      }*/
    }
  }
}

void setup()
{
  size(400, 400);
  background(0);
  world = new float[width][height];
  
  float noiseScale = 0.022;
  for (int i = 0; i < width; i++)
  {
    for (int j = 0; j < height; j++)
    {
      world[i][j] = 20*noise(i*noiseScale, j*noiseScale);
    }
  }
  
  for (int n = 0; n < 10; n++)
  {
    float x = random(0, width);
    float y = random(0, height);
    float theta = random(0, 2*PI);
    float vx = cos(theta);
    float vy = sin(theta);
    for (int i = 0; i < 10; i++)
    {
      float px = wrap((int) (poissonRandom(800)+x), 0, width-1);
      float py = wrap((int) (poissonRandom(800)+y), 0, height-1);
      println("add plate at x:"+px+" y:"+py+" vx:"+vx+" vy:"+vy);
      List<PVector> pos = new ArrayList<PVector>();
      pos.add(new PVector(px, py));
      plates.add(new Plate(pos, vx, vy));
    }
  }
}

void draw()
{
  step(0.01);
  loadPixels();
  for (int i = 0; i < width; i++)
  {
    for (int j = 0; j < height; j++)
    {
      color c = color(world[i][j], world[i][j], world[i][j]);
      if (world[i][j] < 100)
      {
        pixels[j*width+i] = blendColor(c, color(30, 40, 120), SCREEN);
      }
      else
      {
        pixels[j*width+i] = c;
      }
    }
  }
  updatePixels();
  fill(200, 0, 0);
  for (Plate p : plates)
  {
    for (PVector pos : p.getPos())
    {
      ellipse((int)pos.x, (int)pos.y, 10, 10);
    }
  }
}
