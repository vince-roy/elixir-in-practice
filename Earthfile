VERSION 0.6

all:
    BUILD +code-style-and-security
    BUILD +test

deps:
  FROM elixir:1.14.0-alpine
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

test:
  FROM +deps
  RUN apk add --no-progress --update docker docker-compose bash postgresql-client
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