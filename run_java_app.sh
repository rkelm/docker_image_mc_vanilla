#!/bin/bash
# Starts java app.
# Respects env variables.
# Stops app gracefully on trap SIGTERM.

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
	_out=$(ps -o pid | grep -w "$pid")
	if test "$_out"=="$pid" ; then
	    echo "Stopping java app."
	    "${INSTALL_DIR}/bin/stop_java_app.sh"
	    wait "$pid"
	fi
    fi
}

# Trap sigterm sent by docker stop.
trap sigterm_handler SIGTERM

# Change to server directory with configuration files.
# This is the directory where a named docker volume is mounted.
cd "${SERVER_DIR}"
# Run app.
$java_cmd $java_opt ${JAVA_PARAM_PREFIX} -jar $jar_path ${JAVA_PARAM_SUFFIX} &
pid="$!"
echo $pid > ${INSTALL_DIR}/pid.txt

# Wait until app dies.
wait "$pid"
