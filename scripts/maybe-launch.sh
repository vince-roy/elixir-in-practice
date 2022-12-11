#!/bin/sh
set -ex

# Deploy the Fly app, creating it first if needed.
if ! flyctl status --app "$APP_NAME"; then
   flyctl launch \
          --no-deploy \
          --copy-config \
          --name "$APP_NAME" \
          --image "$IMAGE_NAME:$EARTHLY_GIT_HASH" \
          --region "$FLY_REGION" \
          --org "$FLY_ORG"
fi