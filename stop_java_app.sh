#!/bin/bash
# Script to gracefully stop mc server.

function kill_pid()
{
    local pid=$1
    
    echo "Sending SIGTERM to process with pid $pid."
    kill -s SIGTERM $pid

    sleep 10
    _out=$(ps -e -o pid | grep -w "$pid" | tr -d '[:space:]' )
    if test "$pid" = "_out" ; then
	echo "Termination by SIGTERM timed out after 10 seconds."
	echo "Sending SIGKILL."
	kill -s SIGKILL $pid
	exit
    fi
}

function terminate_pid()
{
    local pid=$1

    echo "Waiting max. ${GRACEFUL_STOP_TIMEOUT} seconds for graceful termination of process $pid."
    _out=$( ps -e -o pid | grep -w "$pid" | tr -d '[:space:]' )
    _cnt=0
    while test "$pid" = "$_out" ; do
	sleep 1
	# Process still active?
	_out=$( ps -e -o pid | grep -w "$pid" | tr -d '[:space:]' )
	# Maximum wait time in seconds reached?
	if test "$_cnt" -gt "${GRACEFUL_STOP_TIMEOUT}" ; then
	    echo "Impatiently killing process with pid $pid after waiting $_cnt seconds."
	    kill_pid $pid
	fi
	_cnt=$(($_cnt + 1))
    done
}

echo "Gracefully stopping java app."
#echo "Announcing server stop to users."

#command_cmd="${INSTALL_DIR}/bin/app_cmd.sh"

#$command_cmd 'say Server shutting down in 10 seconds!!'
#echo 'say Server shutting down in 10 seconds!!'
#sleep 5
#$command_cmd 'say Server shutting down in 5 seconds!!'
#echo 'say Server shutting down in 5 seconds!!'
#sleep 2
#$command_cmd 'say Server shutting down in 3 seconds!!'
#'say Server shutting down in 3 seconds!!'
#sleep 1
#$command_cmd 'say Server shutting down in 2 seconds!!'
#'say Server shutting down in 2 seconds!!'
#sleep 1
#$command_cmd 'say Server shutting down in 1 second!!'
#'say Server shutting down in 1 second!!'
#sleep 1
#$command_cmd 'save-all'

$command_cmd 'stop'

# Do we have a process id?
echo "Waiting for java app to terminate on stop command."

# When java app process does not end by itself, then terminate it and the log tailing process.
if test -e "${INSTALL_DIR}/pid_app.txt" ; then
    pid=$( cat "${INSTALL_DIR}/pid_app.txt" )
    terminate_pid "$pid"
    rm "${INSTALL_DIR}/pid_app.txt" > /dev/null
fi

if test -e "${INSTALL_DIR}/pid_tail.txt" ; then
    pid=$( cat "${INSTALL_DIR}/pid_tail.txt" )
    echo "Terminating log tailing process."
    kill_pid "$pid"
    rm "${INSTALL_DIR}/pid_tail.txt" > /dev/null    
fi

