# Script to generate a setup file to perform experiments in terms of the number
# of animals for the wildlife crossing model.
#
# The output is structured as XML to be passed to the BehaviorSpace of NetLogo
# with the experiments named after {n-fences}-{n-passages}.
#
# Usage:
# generate_experiment.sh [-d duration] [-e establishment] [-m mortality]
#  [-r repetitions] [-s setup_file]
# with the following definitions:
# - duration: the number of years the simulation is run (default: 35)
# - establishment: the number of years before the road appears (default: 15)
# - mortality: the mortality road upon crossing the road (default: 0.5)
# - repetitions: the number of times the same simulation is run (default: 3)
# - setup_file: the file to write the output to, or - for standard output
#   (default: experiments-setups.xml)

set -e

while getopts :d:e:m:r: name; do
	case $name in
	d)	duration="$OPTARG";;
	e)	establishment="$OPTARG";;
	m)	mortality="$OPTARG";;
	r)	repetitions="$OPTARG";;
	s)	setup_file="$OPTARG";;
	:)	printf "Option -%c requires an operand\n" "$OPTARG"
		exit 1;;
	?)	printf "Usage: %s [-d duration] [-e establishment] [-m mortality] [-r repetitions] [-s setup_file]\n" "$0"
		exit 1;;
  esac
done

if [ -z "$duration" ]; then
	duration=35
fi

if [ -z "$establishment" ]; then
	establishment=10
fi

if [ -z "$mortality" ]; then
	mortality=0.5
fi

if [ -z "$repetitions" ]; then
	repetitions=3
fi

if [ -z "$setup_file" ]; then
	setup_file="experiments-setups.xml"
fi

rm -f -- "$setup_file"

cat >> "$setup_file" <<END
<?xml version="1.0"?>
<!DOCTYPE experiments SYSTEM "behaviorspace.dtd">
<experiments>
END

for n_fences in 0 6 12 18 24; do
	for n_passages in 0 6 12 18 24; do
cat >> "$setup_file" <<END
	<experiment name="$n_fences-$n_passages" repetitions="$repetitions" runMetricsEveryStep="true">
		<setup>setup</setup>
		<go>go</go>
		<metric>count animals</metric>
		<enumeratedValueSet variable="duration">
			<value value="$duration"/>
		</enumeratedValueSet>
		<enumeratedValueSet variable="establishment">
			<value value="$establishment"/>
		</enumeratedValueSet>
		<enumeratedValueSet variable="mortality">
			<value value="$mortality"/>
		</enumeratedValueSet>
		<enumeratedValueSet variable="n-fences">
			<value value="$n_fences"/>
		</enumeratedValueSet>
		<enumeratedValueSet variable="n-passages">
			<value value="$n_passages"/>
		</enumeratedValueSet>
	</experiment>
END
	done
done

cat >> "$setup_file" <<END
</experiments>
END
