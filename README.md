# clabvailability

Bash based CLAB availability utility script

# how to use

just sudo chmod +x the script and ./clabvailability.sh and you're golden
-h for help
-s to just get a list of all machines and their occupancy status
-i for interactive mode (default)

# Use area

At NTNU there is a lab with 25 desktop machines set up for pytorch, however, you shouldn't use a machine that someone else is using, so instead of SSH-ing back and forth between the machine, let your machine do that job through this script! It'll even ssh into the machine for you!
If all machines are taken it'll loop through all machines untill it finds an available one. The order of machines looped through is randomly permutated so that yain't putting extra pressure on any special machines through this script.
