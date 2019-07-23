#!/bin/bash
# Starts java app.
# Respects env variables.
# Stops app gracefully on trap SIGTERM.

fifo="${INSTALL_DIR}/console.in"
java_cmd="java"
jar_path="${APP_DIR}/${JAR_FILE}"
java_opt=""

if test -n "${JAVA_MAXHEAP}" ; then
    java_opt="$java_opt -Xmx${JAVA_MAXHEAP}"
fi
if test -n "${JAVA_MINHEAP}" ; then
    java_opt="$java_opt -Xms${JAVA_MINHEAP}"
fi

sigterm_handler() {
    # app still running?
    echo "Caught SIGTERM signal."
    if test -n "$pid" ; then
	_out=$(ps -e -o pid | grep -w "$pid" | tr -d '[:space:]' )
	if test "$_out"=="$pid" ; then
	    echo "Stopping java app."
	    "${INSTALL_DIR}/bin/stop_java_app.sh"
	    wait "$pid"
	fi
    fi
}

# Trap sigterm sent by docker stop.
trap sigterm_handler SIGTERM

# Call prepare script if exists.
if test -e "${INSTALL_DIR}/bin/prepare_java_app.sh" -a -x "${INSTALL_DIR}/bin/prepare_java_app.sh" ; then
    "${INSTALL_DIR}/bin/prepare_java_app.sh"
fi

# Change to server directory with configuration files.
# This is the directory where a named docker volume is mounted.
cd "${SERVER_DIR}"
echo "Creating fifo $fifo as stdin of java background process."
[ -e "$fifo" ] && rm $fifo
mkfifo $fifo

# Run app.
tail -n +1 -f ${fifo} | $java_cmd $java_opt ${JAVA_PARAM_PREFIX} -jar $jar_path ${JAVA_PARAM_SUFFIX} &
pid="$!"
# Save pid of process running java app.
echo $pid > ${INSTALL_DIR}/pid_app.txt

# Save pid of process running tail.
# Somehow jobs -x echo %1 always output pid 1, so I'm using jobs -p here.
echo $( jobs -p ) > ${INSTALL_DIR}/pid_tail.txt

# Copy mc log to standard out?
if test "$ECHO_LOG2STDOUT" = "YES" ; then
    echo "Waiting for file ${SERVER_DIR}/logs/latest.log to be created."
    timeout_cnt=0
    while sleep 1 ; do
	if test -e "${SERVER_DIR}/logs/latest.log" ; then
	    echo "Tailing ${SERVER_DIR}/logs/latest.log to stdout."
	    tail -f "${SERVER_DIR}/logs/latest.log" &
	    break
	fi
	((timeout_cnt++))
	if test "$timeout_cnt" -gt "30" ; then
	    echo "Timed out."
	    break
	fi
   done
fi

# Wait until app dies.
echo "Waiting for process with pid $pid to end."
wait "$pid"
echo "Process with pid $pid has ended."
