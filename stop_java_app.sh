#!/bin/ash
# Script to gracefully stop mc server.

echo "Gracefully stopping java app."
echo "Sending stop messages to users."

command_cmd="${INSTALL_DIR}/bin/app_cmd.sh"

$command_cmd 'say Server shutting down in 30 seconds!!'
sleep 20
$command_cmd 'say Server shutting down in 10 seconds!!'
sleep 5
$command_cmd 'say Server shutting down in 5 seconds!!'
sleep 2
$command_cmd 'say "Server shutting down in 3 seconds!!'
sleep 1
$command_cmd 'say "Server shutting down in 2 seconds!!'
sleep 1
$command_cmd 'say Server shutting down in 1 second!!'
sleep 1
$command_cmd 'save-all'
$command_cmd 'stop'

# Do we have a process id?
if test -e "${INSTALL_DIR}/pid.txt" ; then
    pid=$( cat "${INSTALL_DIR}/pid.txt" )
    echo "Waiting for process $pid to terminate..."
    _out=$(ps -o pid | grep -w "$pid")
    cnt=0
    while test "$pid" != "$_out" ; do
	sleep 1
	# Process still active?
	_out=$(ps -o pid | grep -w "$pid")

	cnt=$(($cnt + 1))
	# Maximum wait time in seconds reached?
	if test $cnt -gt 120 ; then
	    echo "Maximum wait time reached. Killing java app with pid $pid."
	    echo "Sending SIGTERM."
	    kill -s SIGTERM $pid
	    sleep ${GRACEFUL_STOP_TIMEOUT}
    	    _out=$(ps -o pid | grep -w "$pid")
	    if test "$pid"=="_out" ; then
		echo "Sending SIGKILL."
		kill -s SIGKILL $pid
		exit
	    fi
	fi
    done
    rm "${INSTALL_DIR}/pid.txt" > /dev/null
fi
