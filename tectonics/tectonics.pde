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
  color c;
  
  Plate(List<PVector> pos, float vx, float vy, color c)
  {
    this.pos = pos;
    this.vx = vx;
    this.vy = vy;
    this.c = c;
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
  for (Plate p : plates)
  {
    if (r == null)
    {
      r = plates.get(0);
    }
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
          double r = 5*poissonRandom(5);
          float theta = random(0, (float) (2 * Math.PI));
          int ru = wrap((int) (r*cos(theta) + u) , 0, width-1);
          int rv = wrap((int) (r*sin(theta) + v), 0, height-1);
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
        tmpWorld[pvx][pvy] += world[i][j];
      }
      
      world[i][j] = 0;
    }
  }
  
  for (int i = 0; i < width; i++)
  {
    for (int j = 0; j < height; j++)
    {
      world[i][j] += (tmpWorld[i][j]
        + tmpWorld[wrap(i+1, 0, width-1)][j]
        + tmpWorld[wrap(i-1, 0, width-1)][j]
        + tmpWorld[i][wrap(j+1, 0, height-1)]
        + tmpWorld[i][wrap(j-1, 0, height-1)]
        + tmpWorld[wrap(i+1, 0, width-1)][wrap(j+1, 0, height-1)]
        + tmpWorld[wrap(i+1, 0, width-1)][wrap(j-1, 0, height-1)]
        + tmpWorld[wrap(i-1, 0, width-1)][wrap(j+1, 0, height-1)]
        + tmpWorld[wrap(i-1, 0, width-1)][wrap(j-1, 0, height-1)])/9;
        
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
      world[i][j] = 20*noise(i*noiseScale, j*noiseScale)+60;
    }
  }
  colorMode(HSB);
  for (int n = 0; n < 10; n++)
  {
    float x = random(0, width-1);
    float y = random(0, height-1);
    float theta = random(0, 2*PI);
    float vx = cos(theta);
    float vy = sin(theta);
    
    // don't put a place near edges
    if (x < 30 && x > width-30 && y < 30 && y > height-30)
    {
      n--;
      continue;
    }
    
    Plate p = getNearestPlate(x, y);
    if (p != null)
    {
      float d = p.distance(new PVector(x, y));
      if (d < 120)
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
    for (int i = 0; i < 40; i++)
    {
      double r = 4 * poissonRandom(10);
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
  step(0.01);
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
}
