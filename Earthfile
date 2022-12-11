VERSION 0.6
ARG IMAGE_NAME=one
ARG ELIXIR_IMAGE=elixir:1.14.2-alpine

all:
    BUILD +code-style-and-security
    BUILD +deploy

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
  FROM alpine:3.16
  RUN wget -q -t3 'https://packages.doppler.com/public/cli/rsa.8004D9FF50437357.key' -O /etc/apk/keys/cli@doppler-8004D9FF50437357.rsa.pub && \
    echo 'https://packages.doppler.com/public/cli/alpine/any-version/main' | tee -a /etc/apk/repositories && \
    apk add doppler 
  RUN apk update && \
    apk add --no-cache openssl ncurses-libs libgcc libstdc++ sed
  WORKDIR /app
  RUN chown nobody:nobody /app
  USER nobody:nobody
  COPY +release/prod/rel/one .
  ENV HOME=/app
  ENV ECTO_IPV6=true
  ENV DISABLE_REDIS="1"
  ENV ERL_AFLAGS "-proto_dist inet6_tcp"
  ENV APP_NAME=one
  ARG EARTHLY_GIT_HASH
  COPY ./scripts/start-app.sh .
  CMD ["./start-app.sh"]

release:
  FROM +deps
  COPY --dir config priv assets lib ./
  RUN mix assets.deploy
  RUN MIX_ENV=prod mix do compile, release
  SAVE ARTIFACT _build/prod AS LOCAL _build/prod

test:
  FROM +deps
  RUN apk add --no-cache \
    curl postgresql-client docker docker-compose jq oniguruma libseccomp \
    runc containerd libmnl libnftnl iptables ip6tables tini-static \
    device-mapper-libs docker-engine docker-cli docker
  COPY ./docker-compose.yml ./docker-compose.yaml
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

deploy:
    FROM +test
    RUN curl -L https://fly.io/install.sh | sh
    WORKDIR /
    RUN mv /root/.fly/bin/flyctl /usr/local/bin
    COPY fly.toml .
    ARG FLY_CONFIG="./fly.toml"
    ARG GITHUB_EVENT_TYPE
    ARG GITHUB_PR_NUMBER
    ARG --required REPO_NAME
    ARG --required REPO_OWNER
    ARG EARTHLY_GIT_HASH
    ARG FLY_POSTGRES_ENABLED=true
    RUN alias flyctl="/root/.fly/bin/flyctl"
    COPY ./scripts/maybe-launch.sh maybe-launch.sh
    COPY ./scripts/maybe-attach-database.sh maybe-attach-database.sh
    IF [ "$EARTHLY_TARGET_TAG_DOCKER" = 'main' ]
        ENV APP_NAME="$REPO_NAME"
    ELSE
        ENV APP_NAME="pr-$GITHUB_$GITHUB_PR_NUMBER-$REPO_OWNER-$REPO_NAME"
    END
    IF [ "$GITHUB_EVENT_TYPE" = "closed" ]
      RUN --secret FLY_POSTGRES_NAME=+secrets/FLY_POSTGRES_NAME \
          flyctl postgres detach --app "$APP_NAME" \
          "$FLY_POSTGRES_NAME"
      RUN --secret FLY_API_TOKEN=+secrets/FLY_API_TOKEN \
          flyctl apps destroy "$APP_NAME" -y 
    END
    IF [ "$EARTHLY_TARGET_TAG_DOCKER" = 'main' ] | [ "$GITHUB_PR_NUMBER" ]
      RUN  --secret FLY_ORG=+secrets/FLY_ORG \
          --secret FLY_REGION=+secrets/FLY_REGION \
          --secret FLY_API_TOKEN=+secrets/FLY_API_TOKEN \
          ./maybe-launch.sh
    END
    WITH DOCKER --load $IMAGE_NAME:$EARTHLY_GIT_HASH=+docker
      IF [ "$EARTHLY_TARGET_TAG_DOCKER" = 'main' ] | [ "$GITHUB_PR_NUMBER" ]
        IF [ ! "$GITHUB_EVENT_TYPE" = "closed" ]
          RUN --secret DOPPLER_TOKEN=+secrets/DOPPLER_TOKEN \
              --secret FLY_REGION=+secrets/FLY_REGION \
              --secret FLY_API_TOKEN=+secrets/FLY_API_TOKEN \
              flyctl deploy \
                --config "$FLY_CONFIG" \
                --app "$APP_NAME" \
                --env DOPPLER_TOKEN=$DOPPLER_TOKEN \
                --image "$IMAGE_NAME:$EARTHLY_GIT_HASH" \
                --region "$FLY_REGION" \
                --strategy immediate \
                --local-only 
        ELSE
          RUN true
        END
      ELSE
        RUN true
      END
    END
    IF [ "$EARTHLY_TARGET_TAG_DOCKER" = 'main' ] | [ "$GITHUB_PR_NUMBER" ]
      RUN --secret FLY_POSTGRES_NAME=+secrets/FLY_POSTGRES_NAME \
        --secret FLY_API_TOKEN=+secrets/FLY_API_TOKEN \
        ./maybe-attach-database.sh
    END