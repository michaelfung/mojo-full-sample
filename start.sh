#!/bin/bash

# start script for the app in production
# set as the CMD part of the docker run command

APP_PORT=${APP_PORT:=3000}

# set Mojo params:
export MOJO_REACTOR=Mojo::Reactor::UV
export MOJO_MAX_MESSAGE_SIZE=67108864   # 64MB
export MOJO_MODE=production
export MOJO_LOG_LEVEL=debug

# launch
cd /app
script/sample_mojo_app prefork -l "http://0.0.0.0:${APP_PORT}"
