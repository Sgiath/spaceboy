FROM hexpm/elixir:1.11.4-erlang-23.3.1-alpine-3.13.3 AS build

# install build dependencies
RUN apk add --no-cache build-base git python3

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix do local.hex --force, local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# Copy mix files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix do deps.get --only ${MIX_ENV}

# Copy configuration
COPY config config

# Compile dependencies
RUN mix deps.compile

# Copy source code
COPY . ./

# Assemble release
RUN mix do compile, release

# ================================================================================================

FROM alpine:3.13.3 AS app

# Runtime dependencies
RUN apk add --no-cache openssl ncurses-libs

ENV USER="spaceboy"
ENV HOME=/home/"${USER}"
ENV APP_DIR="${HOME}/app"

# Creates an unprivileged user to be used exclusively to run the Spaceboy app
RUN addgroup -g 1000 -S "${USER}" && \
  adduser -s /bin/sh -u 1000 -G "${USER}" -h "${HOME}" -D "${USER}" && \
  su "${USER}" sh -c "mkdir ${APP_DIR}"

# System settings
WORKDIR /app

# Everything from this line onwards will run in the context of the unprivileged user.
USER "${USER}"
WORKDIR "${APP_DIR}"

# Copy binaries
COPY --from=build --chown="${USER}":"${USER}" /app/_build/prod/rel/default ./

ENTRYPOINT ["./bin/default"]

CMD start
