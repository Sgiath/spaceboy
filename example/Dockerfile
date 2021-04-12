FROM hexpm/elixir:1.11.4-erlang-23.3.1-alpine-3.13.3 AS build

# install build dependencies
RUN --mount=type=cache,sharing=locked,target=/var/cache/apk \
    apk add build-base git python3

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix do local.hex --force, local.rebar --force

# set build ENV
ARG MIX_ENV=prod

# Copy mix files
COPY mix.exs mix.lock ./

# Install dependencies
RUN --mount=type=cache,target=/root/.hex \
    mix deps.get --only ${MIX_ENV}

# Copy source code
COPY . ./

# Assemble release
RUN mix do compile, release

# ================================================================================================

FROM alpine:3.13.3 AS app

# Runtime dependencies
RUN --mount=type=cache,sharing=locked,target=/var/cache/apk \
    apk add openssl ncurses-libs

ARG USER="spaceboy"
ARG HOME=/home/"${USER}"
ARG APP_DIR="${HOME}/app"

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

EXPOSE 1965
ENTRYPOINT ["./bin/default"]
CMD ["start"]
