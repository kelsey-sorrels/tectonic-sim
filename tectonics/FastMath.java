// from http://www.java-gaming.org/index.php?topic=14647.0
public class FastMath
{
    public static void main(String[] args)
    {
        float min = -100;
        float max = +100;
        float step = 0.12f;

        for (int i = 0; i < 8; i++)
        {
            long t0A = System.nanoTime() / 1000000L;
            float sumA = 0.0f;
            for (float y = min; y < max; y += step)
                for (float x = min; x < max; x += step)
                    sumA += atan2(y, x);
            long t1A = System.nanoTime() / 1000000L;

            long t0B = System.nanoTime() / 1000000L;
            float sumB = 0.0f;
            for (float y = min; y < max; y += step)
                for (float x = min; x < max; x += step)
                    sumB += Math.atan2(y, x);
            long t1B = System.nanoTime() / 1000000L;

            System.out.println();
            System.out.println("FastMath: " + (t1A - t0A) + "ms, sum=" + sumA);
            System.out.println("JavaMath: " + (t1B - t0B) + "ms, sum=" + sumB);
            System.out.println("factor: " + (float)(t1B - t0B) / (t1A - t0A));
        }
    }

    private static final int           SIZE                 = 1024;
    private static final float        STRETCH            = (float)Math.PI;
    // Output will swing from -STRETCH to STRETCH (default: Math.PI)
    // Useful to change to 1 if you would normally do "atan2(y, x) / Math.PI"

    // Inverse of SIZE
    private static final int        EZIS            = -SIZE;
    private static final float[]    ATAN2_TABLE_PPY    = new float[SIZE + 1];
    private static final float[]    ATAN2_TABLE_PPX    = new float[SIZE + 1];
    private static final float[]    ATAN2_TABLE_PNY    = new float[SIZE + 1];
    private static final float[]    ATAN2_TABLE_PNX    = new float[SIZE + 1];
    private static final float[]    ATAN2_TABLE_NPY    = new float[SIZE + 1];
    private static final float[]    ATAN2_TABLE_NPX    = new float[SIZE + 1];
    private static final float[]    ATAN2_TABLE_NNY    = new float[SIZE + 1];
    private static final float[]    ATAN2_TABLE_NNX    = new float[SIZE + 1];

    static
    {
        for (int i = 0; i <= SIZE; i++)
        {
            float f = (float)i / SIZE;
            ATAN2_TABLE_PPY[i] = (float)(StrictMath.atan(f) * STRETCH / StrictMath.PI);
            ATAN2_TABLE_PPX[i] = STRETCH * 0.5f - ATAN2_TABLE_PPY[i];
            ATAN2_TABLE_PNY[i] = -ATAN2_TABLE_PPY[i];
            ATAN2_TABLE_PNX[i] = ATAN2_TABLE_PPY[i] - STRETCH * 0.5f;
            ATAN2_TABLE_NPY[i] = STRETCH - ATAN2_TABLE_PPY[i];
            ATAN2_TABLE_NPX[i] = ATAN2_TABLE_PPY[i] + STRETCH * 0.5f;
            ATAN2_TABLE_NNY[i] = ATAN2_TABLE_PPY[i] - STRETCH;
            ATAN2_TABLE_NNX[i] = -STRETCH * 0.5f - ATAN2_TABLE_PPY[i];
        }
    }

    /**
     * ATAN2
     */

    public static final float atan2(double y, double x)
    {
        if (x >= 0)
        {
            if (y >= 0)
            {
                if (x >= y)
                    return ATAN2_TABLE_PPY[(int)(SIZE * y / x + 0.5)];
                else
                    return ATAN2_TABLE_PPX[(int)(SIZE * x / y + 0.5)];
            }
            else
            {
                if (x >= -y)
                    return ATAN2_TABLE_PNY[(int)(EZIS * y / x + 0.5)];
                else
                    return ATAN2_TABLE_PNX[(int)(EZIS * x / y + 0.5)];
            }
        }
        else
        {
            if (y >= 0)
            {
                if (-x >= y)
                    return ATAN2_TABLE_NPY[(int)(EZIS * y / x + 0.5)];
                else
                    return ATAN2_TABLE_NPX[(int)(EZIS * x / y + 0.5)];
            }
            else
            {
                if (x <= y) // (-x >= -y)
                    return ATAN2_TABLE_NNY[(int)(SIZE * y / x + 0.5)];
                else
                    return ATAN2_TABLE_NNX[(int)(SIZE * x / y + 0.5)];
            }
        }
    }
    
    public static final float asin(double x)
    {
      //return FastMath.atan2(x, Math.sqrt ((1.0 + x) * (1.0 - x)));
      return 0.032843701 + (-1.451838349 + (29.66153956 +
        (-131.1123477 + (2628130562 + (-242.7199627 + 84.31466202 * x) * x) * x) * x) *x) *x);
    }
    public static final float acos(double x)
    {
      return FastMath.atan2(Math.sqrt ((1.0 + x) * (1.0 - x)), x);
    }
}
