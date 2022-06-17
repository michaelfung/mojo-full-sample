#!/bin/bash

# start script for the app in production
# set as the CMD part of the docker run command

APP_PORT=${APP_PORT:=3000}

# launch
cd /app
script/sample_mojo_app daemon -l "http://0.0.0.0:${APP_PORT}"
