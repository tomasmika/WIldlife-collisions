# Wildlife Collisions

This repository contains a NetLogo model to simulate the amount of martens in a world over time after which a road splits the world in two sides and animals can suddenly be hit by cars. Fortunately, passages and fences can be added to the world to help animals crossing the road safely.

The model is written for [NetLogo 6.1.1](https://ccl.northwestern.edu/netlogo/6.1.1/) and is completely self-contained in `Wildlife Collisions.nlogo`. Information about the working of the model can be found in the Info Tab of this model.

## Generating animal count over time

To programmatically extract the amount of animals for different number of fences and passages over time on UNIX systems, the `generate_experiment.sh` POSIX shell script can be used for generating a XML setup file to be passed to the [BehaviorSpace  of NetLogo](https://ccl.northwestern.edu/netlogo/docs/behaviorspace.html). The `run_experiment.sh` POSIX shell script can be used to automatically run the simulations for such a setup file, to generate CSV files of the animal count. The exact options for these scripts are documented within the script, with a short usage notice shown upon calling the script with the `?` option.

### Plotting the data

After the CSV files have been generated, the data over time can be plotted using the [Python 3](https://www.python.org/) script `plot.py`, as long as the dependency on [Numpy](https://numpy.org/) and [Matplotlib](https://matplotlib.org/) are fulfilled, which can be used in a library way by importing the script. The exact options for this script are documented within the script, with a short usage notice shown upon calling the script with the `h` option.

### Sample files

To get a general feeling on how the animal count is distributed over time, pre-cached data is present in the `ratio_mean.csv` and `ratio_std.csv` files. The resulting plot can be simply shown by executing the `plot.py` script, as stated above.

The data within these files corresponds to a model with a mortality rate of 50% and is generated out of six simulation runs for each full identical set of parameters. The road in this model establishes after 10 years, while the simulations stops after having simulated 35 years.
