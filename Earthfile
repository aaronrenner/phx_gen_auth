all-test:
  BUILD --build-arg ELIXIR=1.11.4 --build-arg OTP=23.2.7.1 --build-arg ALPINE=3.13.3 +test
  BUILD --build-arg ELIXIR=1.8.2 --build-arg OTP=21.3.8.21 --build-arg ALPINE=3.13.1 +test

test:
  FROM +setup
  # Check formatting
  RUN mix format --check-formatted

  # Run unit tests
  RUN mix test --exclude integration

integration-test:
  FROM +setup

  # Silent git in test output
  RUN git config --global init.defaultBranch master

  RUN apk add --no-progress --update docker docker-compose

  # Install tooling needed to check if the DBs are actually up when performing integration tests
  RUN apk add postgresql-client mysql-client
  RUN apk add --no-cache curl gnupg --virtual .build-dependencies -- && \
      curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.5.2.1-1_amd64.apk && \
      curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.5.2.1-1_amd64.apk && \
      echo y | apk add --allow-untrusted msodbcsql17_17.5.2.1-1_amd64.apk mssql-tools_17.5.2.1-1_amd64.apk && \
      apk del .build-dependencies && rm -f msodbcsql*.sig mssql-tools*.apk
  ENV PATH="/opt/mssql-tools/bin:${PATH}"

  COPY docker-compose.yml ./

  WITH DOCKER
    # Start docker compose
    # In parallel start compiling tests
    # Check for DB to be up x 3
    # Run the database tests
    RUN docker-compose up -d & \
      MIX_ENV=test mix deps.compile && \
      while ! sqlcmd -S tcp:localhost,1433 -U sa -P 'some!Password' -Q "SELECT 1" > /dev/null 2>&1; do sleep 1; done; \
      while ! mysqladmin ping --host=localhost --port=3306 --protocol=TCP --silent; do sleep 1; done; \
      while ! pg_isready --host=localhost --port=5432 --quiet; do sleep 1; done; \
      mix test --only integration
  END

setup:
  ARG ELIXIR=1.11.4
  ARG OTP=23.2.7.1
  ARG ALPINE=3.13.3
  FROM hexpm/elixir:$ELIXIR-erlang-$OTP-alpine-$ALPINE
  RUN apk add --no-progress --update git build-base
  WORKDIR /src

  COPY mix.exs .
  COPY mix.lock .
  COPY .formatter.exs .
  RUN mix local.rebar --force
  RUN mix local.hex --force
  RUN mix deps.get

  RUN MIX_ENV=test mix deps.compile
  COPY --dir lib priv test ./

  # Compile app
  RUN MIX_ENV=test mix compile --warnings-as-errors