#!/bin/sh
set -ex

app_name_pascal_case=$(echo $APP_NAME | sed -r 's/(^|_)([a-z])/\U\2/g')
doppler run -- eval "bin/${APP_NAME} ${app_name_pascal_case}.Release.migrate" && doppler run -- eval "bin/${APP_NAME} start"
