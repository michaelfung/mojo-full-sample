#!/bin/bash
CMD=$1

# source /app/rtenv.rc if it exists to setup runtime environment
[ -f "/app/rt-env.sh" ] && source /app/rt-env.sh

exec $CMD ${@:2}
