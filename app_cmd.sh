#!/bin/bash
# Multiple commands may be passed, but each command and its parameters must be single or double quoted.

${INSTALL_DIR}/bin/mcrcon -H 127.0.0.1 -p "${RCONPWD}" "$@"
