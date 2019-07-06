#!/bin/bash
# Multiple commands may be passed, but each command and its parameters must be single or double quoted.

# Try to send command via rcon.
${INSTALL_DIR}/bin/mcrcon -H 127.0.0.1 -p "${RCONPWD}" "$@"
_res=$?
# Did sending fail? Then send command via fifo to stdin.
if test "$_res" -ne "0" ; then
    echo "rcon failed. Sending command via stdin."
    echo "$@" >> "${INSTALL_DIR}/console.in"
fi

