#!/bin/sh
set -ex

# Default the Fly app name to pr-{number}-{repo_owner}-{repo_name}
app="${APP_NAME:-pr-$PR_NUMBER-$REPO_OWNER-$REPO_NAME}"
# default to New Jersey
region="${FLY_REGION:-ewr}" 
org="${FLY_ORG:-personal}"
image="$IMAGE"
config="./fly.toml"

if ! echo "$app" | grep "$PR_NUMBER"; then
  echo "For safety, this action requires the app's name to contain the PR number."
  exit 1
fi

# PR was closed - remove the Fly app if one exists and exit.
if [ "$GITHUB_EVENT_TYPE" = "closed" ]; then
  flyctl apps destroy "$app" -y || true
  exit 0
fi

# Deploy the Fly app, creating it first if needed.
if ! flyctl status --app "$app"; then
  flyctl launch --no-deploy --copy-config --name "$app" --image "$image" --region "$region" --org "$org"
  flyctl deploy --app "$app" --region "$region" --image "$image" --region "$region" --strategy immediate
elif [ "$INPUT_UPDATE" != "false" ]; then
  flyctl deploy --config "$config" --app "$app" --region "$region" --image "$image" --region "$region" --strategy immediate
fi

# Attach postgres cluster to the app if specified.
if [ -n "$FLY_POSTGRES_NAME" ]; then
  flyctl postgres attach --postgres-app "$FLY_POSTGRES_NAME" || true
fi

# Make some info available to the GitHub workflow.
# fly status --app "$app" --json >status.json
