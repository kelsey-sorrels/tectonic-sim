tectonic-sim
============

A prototype tectonic simulator written in Processing.

<img src="https://raw.github.com/aaron-santos/tectonic-sim/master/doc/ss1.png" />

## Method of simulation
# Create plates
  * For n plates
    * Pick a random point (x,y) that is a minimum distance away from existing plates
    * Give the plate a random velocity (speed, direction)
  * For n plates
    * Pick m random point (x,y) centered around (plate.x, plate.y) and add it to the plate
  * Seed the world's initial elevation map with some noise

# Step
  * Create a temporary elevation map initialized to zero
  * For each point (i,j) on the elevation map
    * Find the velocity of the plate with the nearest point to (i,j)
    * Using the velocity, move the elevation value from the elevation map to the
      temporary elevation map. If there is already a value at the destination,
      scatter the value across the temporary map
  * Copy the temporary map back to the map