#!/usr/bin/env bash

#CLAB AVAILABILITY CHECKER UTILITY SCRIPT
#Written by: Bendik Bogfjellmo (bendik.bogfjellmo@gmail.com)
#Feel free to use this stuff later on, but don't blame me if it fucks your shit up


#If you have any feature requests or improvement ideas, just email me a wish or an implementation
#I know this script is a piece of procedurally written garbage, but CBA to look up bash function syntax for the 27th time
#Besides, it works on my machine, so IDC ;)


#Get requested user mode
case $1 in
	""|" "|-i|-I|--Interactive|--interactive)
	MODE="INTERACTIVE"
	;;
	-s|-S|--Status|--status)
	MODE="STATUS"
	;;
	-h|-H|--Help|--help)
	MODE="HELP"
	;;
	*)
	MODE="UNKNOWN"
	ARG=$1 #to feed back to user
	;;
esac


#Install packages if user doesn't have
PACKAGES=("sshpass" "shuf")
for PACKAGE in "${PACKAGES[@]}"
do
	if ! which $PACKAGE > /dev/null; then
		echo -e "$PACKAGE is needed for this script and was not found! Install? (y/n) \c"
		read
		if [ "$REPLY" == "y" ]; then
			sudo apt-get install $PACKAGE
		fi
	fi
done


#Code block to get a *valid* username and password for the clab machines
if [ "$MODE" = "INTERACTIVE" ] || [ "$MODE" = "STATUS" ]; then
	VALID="FALSE"
	MACHINE_LIST=($(seq -w 01 25))
	while [ "$VALID" == "FALSE" ]; do
		echo "enter ntnu-username:"
		read
		USERNAME=$REPLY
		echo
		echo "If you're worried I'm gonna steal ya password, just check out the variable declared at line 56 in the script"
		echo
		echo "enter ntnu-password:"
		read -s
		PASSWORD=$REPLY
		WHOAMI="  slurm cluster for TDT4200  " #shitty ""temporary hack"" (lol, as if) to avoid trial on one of the slurm machines
		while [[ "$WHOAMI" == *"slurm cluster for TDT4200"* ]]; do
			MACHINE_LIST=($(seq -w 01 25))
			RANDNUM=$[$RANDOM % 25]
			RANDOM_MACHINE=${MACHINE_LIST[$RANDNUM]}
			WHOAMI=$(sshpass -p $PASSWORD ssh ${USERNAME}@clab${RANDOM_MACHINE}.idi.ntnu.no whoami)
		done
		if [ "$WHOAMI" == "$USERNAME" ]; then #if the whoami command on the host machine has returned our username a valid login has been performed
			VALID="TRUE"
		else
			echo "wrong password and/or username, please try again"
			echo
			echo "Alternatively, you can ctrl+c to just give up"
			echo
		fi
	done
fi


#Code block for interactive mode, will set up ssh for the user
if [ "$MODE" == "INTERACTIVE" ] && [ "$VALID" == "TRUE" ]; then

	SHUFFLED_MACHINE_LIST=$(seq -w 01 25 | shuf) #not exactly 78 billion lines, but oh well, at least it'll do it faster than a minute
	#btw, if you're actually reading this shit, got that joke, and found it funny, please email me "nice meme dude", it'll make my day, I promise

	echo "Looking for available machine to connect to..."
	CONNECTED=""
	declare -i LOOP_COUNTER=0
	while [ "$CONNECTED" == "" ]; do
		if [ "$LOOP_COUNTER" == "1" ]; then #If for loop has looped once, it means all machines are busy, so give the user some fun feedback as they're probably having a bad time
			echo "Looks like all the machines are busy, best just chill out for a while"
			sleep 2
			echo "grab some coffee, tea, a snack, or something like that."
			sleep 3
			echo "I'll just loop through the machines in the meantime to find one for ya,"
			sleep 4
			echo "Don't worry, I'll update you along the way, so you know I'm not slacking off"
			sleep 5
			echo "I think I'm a bit faster than you, so best just leave it to me ;)"
			sleep 5
			echo "Alright, back to work (for me)"
			sleep 4
		fi
		for NO in ${SHUFFLED_MACHINE_LIST}
		do
			USERS=$(sshpass -p $PASSWORD ssh ${USERNAME}@clab${NO}.idi.ntnu.no users)
			if [ "$USERS" == "" ]; then
				SLURMCHECK=$(sshpass -p $PASSWORD ssh ${USERNAME}@clab${RANDOM_MACHINE}.idi.ntnu.no whoami)
				if [ "$SLURMCHECK" != *"$USERNAME"* ]; then
					echo "Machine no. $NO is available!"
					sshpass -p $PASSWORD ssh ${USERNAME}@clab${NO}.idi.ntnu.no -oStrictHostKeyChecking=no
					sleep 1
					CONNECTED="TRUE"
					break
				fi
			fi
		done
		if [ "$LOOP_COUNTER" -gt "1" ];then
			clear
			echo "So far, I've checked through all the machines in the lab $LOOP_COUNTER times"
		fi
		LOOP_COUNTER=$((LOOP_COUNTER+1))
	done
fi


#Help mode block
if [ "$MODE" == "HELP" ]; then
	echo "CLAB labspot aVAILABILITY script"
	echo
	echo "-h/-H/--Help/--help for help"
	echo
	echo "-s/-S/--Status/--status to just view status and not connect"
	echo
	echo "(default) or -i/-I/--Interactive/--interactive to make script connect for you" 
	echo
	echo "If you've found a bug or have any other problems,"
	echo "just email me at bendik.bogfjellmo@gmail.com"
fi


#Status mode block, should just give the user an overview over machine availability
if [ "$MODE" == "STATUS" ] && [ "$VALID" == "TRUE" ]; then
	AVAILABLES=()
	OCCUPIED=()
	echo
	echo "Acquiring status map of available machines..."
	ORDERED_MACHINE_LIST=$(seq -w 01 25)
	for NO in ${ORDERED_MACHINE_LIST}; do
		USERS=$(sshpass -p $PASSWORD ssh ${USERNAME}@clab${NO}.idi.ntnu.no users)
		if [ "$USERS" == "" ]; then
			echo "Machine $NO is available"
			AVAILABLES+=$NO
		else
			echo "Machine $NO is occupied"
			OCCUPIED+=$NO
		fi
	done
fi


#If unknown argument were passed
if [ "$MODE" == "UNKNOWN" ]; then
	echo "Unknown argument: '$ARG', for help, run ./clabvailability -h"
fi

