#!/bin/bash

export debug=1

hostname
export HOSTNAME=$(hostname)
dirname $0
export DIRNAME=$(dirname $0)

export statfile=$DIRNAME/$HOSTNAME.rsnapshot.stat
export cycle=$(cat $statfile)

export rsnapshotconf=/etc/rsnapshot.conf

function dbgpr() {
	if [ $debug == 1 ]
		then echo $0":" "$@" >&2
	fi
}

function checknext() {
    backuptype=$1
    rotations=$2
    levels=$3
    cycle=$4
    	dbgpr "Checknext has these informations: Backuptype: $backuptype Rotations: $rotations Levels: $levels Cycle: $cycle"
	dbgpr "Checking if rotations of $backuptype (should be: $rotations) have been completed (is this cycle divisible by the number of rotations times previous backup types?)"
	dbgpr "This is calculated $cycle \% ( $levels \* $rotations)."
	#dbgpr "$[ $cycle % $[$levels*$rotations] ]"
	if [ $[ $cycle % $[$levels*$rotations] ] == 0 ]
	then
		dbgpr "IS DIVISIBLE"
		return 0
	else
		dbgpr "NOT DIVISIBLE"
		return 1
	fi
}

function check_levels() {
    levels=$1
    cycle=$2
    dbgpr "Check_levels has these informations: Levels: $levels Cycle: $cycle "
    if [ $levels == 0 ]
    then
        echo $runthis
    fi
    dbgpr "check_levels running with $1 passed to levels variable ($levels)"
    #echo $(grep "^retain" $rsnapshotconf|head -n $levels|tail -n 1)
    #echo $(grep "^retain" $rsnapshotconf|head -n $levels|tail -n 1)|IFS="	" read retain backuptype rotations
    rawline=$(grep "^retain" $rsnapshotconf|head -n $levels|tail -n 1)
    splitraw=( $rawline )
    backuptype=${splitraw[1]}
    rotations=${splitraw[2]}
    dbgpr "Check_levels: Rawline is $rawline"
    dbgpr "Check levels extracted these informations from $rsnapshotconf: Backuptype: $backuptype Rotations: $rotations Levels: $levels"
    if checknext $backuptype $rotations $levels $cycle
    then
        echo "$backuptype"
	return 0
    else
        echo "$backuptype"
	return 1
    fi
}

function run_backup_instance() {
	runthis=$1
	levels=$2
	dbgpr "### Running rsnapshot with -v and $runthis this corresponds to level $levels . ###"
	if [[ $test == "1" ]]
	then
		echo "Not really running. Only a test."
	else
		rsnapshot $runthis||echo "$0: rsnapshot could not run properly. Exiting..."||exit #remove 'echo' to make shit real
		[[ $? == 1 ]]&&dbgpr "rsnapshot could not run properly. Exiting..."&&exit #remove 'echo' to make shit real
	fi
}

function do_backup() {
	levels=$1
	runthis=$2
	cycle=$3
	finished="0"
    until [[ $finished == 1 ]]
	do
	if [[ $runthis == "sync" ]]
	then #Run sync if sync first is enabled
		run_backup_instance $runthis $levels
	fi
        dbgpr "Increasing levels variable..."
        levels=$[$levels + 1]
        dbgpr "levels is now $levels"
        nextlevel=$(check_levels $levels $cycle)
	if [[ $? == 1 ]]; then finished=1;fi
        #check_levels $levels $cycle|tail -n 1|read nextlevel finished
        dbgpr "do_backup: nextlevel is now $nextlevel and finished-status is $finished"
        runthis=$nextlevel
	run_backup_instance $runthis $levels
	
	done
}

if grep "^sync_first	1" $rsnapshotconf
then
    dbgpr "Sync first is enabled. Setting levels and runthis to 0 and sync"
    export levels=0
    dbgpr "Levels is now $levels"
    export runthis="sync"
else
    runthis="skip"
fi

dbgpr "Host: $HOSTNAME and Statfile: $statfile"
[[ ! -f $statfile ]] && echo "Statfile $statfile does not exist. Attempting to create it in script path ($DIRNAME)..."&&echo 1 > $statfile
dbgpr "This is backup number $cycle since last spin (read from statfile)."
do_backup $levels $runthis $cycle
[[ $test == 1 ]]&&dbgpr "This was only a test. Not altering statfile (it may have been created though)."
[[ $test != 1 ]]&&dbgpr "Adding completed round (echo $cycle + 1) in statfile... ($statfile)" && echo $[cycle+1] > $statfile
echo "And we're done"
