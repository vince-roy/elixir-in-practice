VERSION 0.6
ARG IMAGE_NAME=one
ARG ELIXIR_IMAGE=elixir:1.14.2-alpine

all:
    BUILD +code-style-and-security
    BUILD +test

deps:
  ARG ELIXIR_IMAGE
  FROM $ELIXIR_IMAGE
  RUN apk add --no-progress --update git build-base
  WORKDIR /src
  COPY mix.exs .
  COPY mix.lock .
  COPY .formatter.exs .
  RUN mix local.rebar --force
  RUN mix local.hex --force
  RUN mix deps.get
  RUN MIX_ENV=test mix deps.compile
  RUN mix deps.compile

code-style-and-security:
    FROM +deps
    COPY --dir config lib priv test .credo.exs .formatter.exs .
    RUN MIX_ENV=test mix credo --strict && \
        MIX_ENV=test mix format --check-formatted
    RUN MIX_ENV=test mix deps.audit 

docker: 
  FROM alpine3.16
  RUN wget -q -t3 'https://packages.doppler.com/public/cli/rsa.8004D9FF50437357.key' -O /etc/apk/keys/cli@doppler-8004D9FF50437357.rsa.pub && \
    echo 'https://packages.doppler.com/public/cli/alpine/any-version/main' | tee -a /etc/apk/repositories && \
    apk add doppler
  RUN apk update && \
    apk add --no-cache openssl ncurses-libs libgcc libstdc++
  WORKDIR /app
  RUN chown nobody:nobody /app
  USER nobody:nobody
  COPY +release/app/_build/prod/rel/one .
  ENV HOME=/app
  ENV ECTO_IPV6=true
  ENV DISABLE_REDIS="1"
  ENV ERL_AFLAGS "-proto_dist inet6_tcp"
  ARG EARTHLY_GIT_HASH
  CMD doppler run -- bin/lire eval "Lire.Release.migrate" && doppler run -- bin/lire start

test:
  FROM +deps
  RUN apk add --no-progress --update docker docker-compose bash postgresql-client jq
  COPY ./docker-compose.yml ./docker-compose.yml
  COPY --dir config lib priv test .
  RUN DATABASE_URL="ecto://postgres:postgres@localhost/test" MIX_ENV=test mix compile

  WITH DOCKER
      # Start docker compose
      # In parallel start compiling tests
      # Check for DB to be up x 3
      # Run the database tests
    RUN docker-compose up -d & \
          while ! pg_isready --host=localhost --port=5432 --quiet; do sleep 1; done; \
          DATABASE_URL="ecto://postgres:postgres@localhost/test" \
          mix test 
  END

deploy-preview:
    ARG GITHUB_PR_NUMBER
    # move env to Doppler
    # ARG FLY_ORG=personal
    # ARG FLY_REGION=ewr
    # ARG POSTGRES_NAME=preview
    # ARG PR_NUMBER
    # ARG REPO_NAME
    # ARG REPO_OWNER
    # ARG PHX_HOST
    # get CI doppler token?
    RUN DOPPLER_TOKEN=+secrets/DOPPLER doppler run -- ./scripts/fly-deploy.sh

deploy-production:
    ARG APP_NAME=production
    ARG EARTHLY_GIT_HASH
    WITH DOCKER --load $IMAGE_NAME:$EARTHLY_GIT_HASH=+docker
        RUN --secret DOPPLER_TOKEN=+secrets/DOPPLER doppler run --  /root/.fly/bin/flyctl deploy \
        --image $IMAGE_NAME:$EARTHLY_GIT_HASH --local-only \
        --env DOPPLER_TOKEN=$DOPPLER_TOKEN
    END