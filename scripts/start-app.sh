#!/bin/sh
set -ex

app_name_pascal_case=$(echo $APP_NAME | sed -r 's/(^|_)([a-z])/\U\2/g')
doppler run -- /app/bin/${APP_NAME} eval "${app_name_pascal_case}.Release.migrate"
doppler run -- /app/bin/${APP_NAME} start
