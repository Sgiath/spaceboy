ARG ELIXIR_VERSION=1.18.1
ARG OTP_VERSION=27.2
ARG ALPINE_VERSION=3.21.0

ARG BUILD_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${ALPINE_VERSION}"
ARG RUN_IMAGE="alpine:${ALPINE_VERSION}"

# ================================================================================================

FROM ${BUILD_IMAGE} as build

# install build dependencies
RUN apk add build-base git python3

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix do local.hex --force, local.rebar --force

# set build ENV
ARG MIX_ENV=prod

# Copy mix files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get --only ${MIX_ENV}

# Copy configuration
RUN mkdir config
COPY config/config.exs config/${MIX_ENV}.exs config/

# Compile dependencies
RUN mix deps.compile

# Copy source code
COPY lib lib

# Compile
COPY priv priv
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

# Assemble release
COPY rel rel
RUN mix release

# ================================================================================================

FROM ${RUN_IMAGE}

# Runtime dependencies
RUN apk add openssl ncurses-libs

# System settings
WORKDIR /app
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV=prod

# Copy binaries
COPY --from=build --chown=nobody:root /app/_build/${MIX_ENV}/rel/default ./

USER nobody

EXPOSE 1965
ENTRYPOINT ["./bin/default"]
CMD ["start"]
