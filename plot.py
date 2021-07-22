# Plot the CSV data generated from the BehaviorSpace setup file and
# placed in directories with files in the form of
# {n-fences}-{n-passages}.csv named.
#
# When given the -r option, the data is read from the directories
# passed as argument to compute the needed data from the CSV files.
# To fasten further processing, this data is then cached in the
# ratio_mean.csv and ratio_std.csv files, placed in the current
# working directory.
#
# The plot is afterwards made by using Matplotlib which can be
# customised by setting system settings.

import argparse
import matplotlib.pyplot as plt
import numpy as np
import os

DAYS_PER_MONTH = 30
MONTHS_PER_YEAR = 12

TICKS_PER_DAY = 20
TICKS_PER_MONTH = TICKS_PER_DAY * DAYS_PER_MONTH
TICKS_PER_YEAR = TICKS_PER_MONTH * MONTHS_PER_YEAR


def is_last_pre_est(tick, est):
    """ Returns true if the tick belongs to the last year before road
    establishment (specified by est)
    """
    return tick >= (est - 1) * TICKS_PER_YEAR and tick < est * TICKS_PER_YEAR


def is_last_post_est(tick, dur):
    """ Returns true if the tick belongs to the last year of the
    simulation (specified by dur)
    """
    return tick >= (dur - 1) * TICKS_PER_YEAR and tick < dur * TICKS_PER_YEAR


def parse_file(fname):
    """ Parses file of the form 'n_fences-n_passages.csv' and
    retrieves average pre est. and post est. population sizes
    of all simulations
    """
    with open(fname) as file:
        run_count = 1
        # Stores the population size in the last year before and after
        # establishment of a road respectively.
        pre_est = np.empty((run_count, TICKS_PER_YEAR), dtype=int)
        post_est = np.empty((run_count, TICKS_PER_YEAR), dtype=int)
        # Stores the index in pre_est and post_est respectively.
        pre_ctr = np.zeros(run_count, dtype=int)
        post_ctr = np.zeros(run_count, dtype=int)

        # Skip first seven header linese.
        for _ in range(7):
            line = next(file)

        # Iterate over all entries in the .csv file and retrieve
        # pre and post est. pop-sizes. Note that we use [1:-1] to
        # remove " surrounding numbers, and [1:-2] to also remove \n.
        for line in file:
            # Lines are in the following format:
            # [run number], duration, establishment, ..., [step], count
            vals = line.split(",")

            run = int(vals[0][1:-1]) - 1
            dur = int(vals[1][1:-1])
            est = int(vals[2][1:-1])
            tick = int(vals[-2][1:-1])

            if run >= run_count:
                n_add = run - run_count + 1
                pre_est = np.append(
                 pre_est, np.empty((n_add, TICKS_PER_YEAR), dtype=int), 0)
                post_est = np.append(
                 post_est, np.empty((n_add, TICKS_PER_YEAR), dtype=int), 0)
                pre_ctr = np.append(pre_ctr, np.zeros(n_add, dtype=int))
                post_ctr = np.append(post_ctr, np.zeros(n_add, dtype=int))
                run_count = run + 1

            if is_last_pre_est(tick, est):
                pre_est[run, pre_ctr[run]] = int(vals[-1][1:-2])
                pre_ctr[run] += 1
            elif is_last_post_est(tick, dur):
                post_est[run, post_ctr[run]] = int(vals[-1][1:-2])
                post_ctr[run] += 1

        return np.average(pre_est, axis=1), np.average(post_est, axis=1)


if __name__ == "__main__":
    count_pas = (0, 6, 12, 18, 24)
    count_fen = (0, 6, 12, 18, 24)

    parser = argparse.ArgumentParser(
     description="Plot the animal count over time.")
    parser.add_argument("-r", "--read-data", metavar="dir", nargs="+",
                        help="directories to read input from")
    args = parser.parse_args()

    if args.reload_data:
        ratio_mean = np.zeros((len(count_pas), len(count_fen)))
        ratio_std = np.zeros((len(count_pas), len(count_fen)))

        # Iterate over all files and retrieve average pre establishment
        # and average post establishment population sizes over multiple runs
        # Then compute ratios, the mean and stddev.
        for i, n_pas in enumerate(count_pas):
            for j, n_fen in enumerate(count_fen):
                pre_est = np.zeros(0, dtype=int)
                post_est = np.zeros(0, dtype=int)

                # For every dirname, we extract all averages and combine them
                for dirname in args.reload_data:
                    fname = str(n_fen) + "-" + str(n_pas) + ".csv"
                    pre_est_temp, post_est_temp = parse_file(
                     os.path.join(dirname, fname))
                    pre_est = np.concatenate((pre_est, pre_est_temp))
                    post_est = np.concatenate((post_est, post_est_temp))

                ratios = post_est / pre_est
                ratio_mean[i, j] = np.average(ratios)
                ratio_std[i, j] = np.std(ratios)

        np.savetxt("ratio_mean.csv", ratio_mean)
        np.savetxt("ratio_std.csv", ratio_std)
    else:
        ratio_mean = np.loadtxt("ratio_mean.csv")
        ratio_std = np.loadtxt("ratio_std.csv")

    total_pas = len(count_pas)

    # Now we plot the ratio of post establishment to pre establishment.
    for i, n_pas in enumerate(count_pas):
        # Trick to create a gradient for our graphs.
        col = (0,
               float(i + 1) / (total_pas + 2),
               float(total_pas + 1 - i) / (total_pas + 2))
        plt.errorbar(count_fen, ratio_mean[i], ratio_std[i],
                     label=str(n_pas)+" passages", color=col)

    plt.xlabel("Number of fences")
    plt.ylabel("Animal count ration (pre over post establishment)")
    plt.title("Animal population impact by placement of fences and passages")

    plt.legend(loc="upper left")
    plt.show()
