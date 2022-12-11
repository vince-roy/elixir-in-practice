#!/bin/sh
set -ex

flyctl postgres attach \
    --app "$APP_NAME" \
    --database-name "$APP_NAME" \
    -y \
    "$FLY_POSTGRES_NAME" || true