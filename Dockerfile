ARG ALPINE_VERSION=3.15.3
ARG ELIXIR_VERSION=1.13.4
ARG ERLANG_VERSION=24.3.4

# Builder Stage

FROM hexpm/elixir:$ELIXIR_VERSION-erlang-$ERLANG_VERSION-alpine-$ALPINE_VERSION as builder

RUN mix local.hex --force \
 && mix local.rebar --force

# Release Stage

FROM builder as release

ARG MIX_ENV

WORKDIR /tmp

ENV MIX_ENV=${MIX_ENV:-prod}

COPY config config
COPY mix.exs mix.lock ./
COPY apps/two_eleven/mix.exs apps/two_eleven/mix.exs
COPY apps/two_eleven_web/mix.exs apps/two_eleven_web/mix.exs

RUN mix deps.get --only $MIX_ENV \
 && mix deps.compile

COPY apps/two_eleven/lib apps/two_eleven/lib
COPY apps/two_eleven_web/assets apps/two_eleven_web/assets
COPY apps/two_eleven_web/lib apps/two_eleven_web/lib
COPY apps/two_eleven_web/lib apps/two_eleven_web/lib

RUN mix setup \
 && mix cmd --app two_eleven_web mix assets.deploy \
 && mix phx.digest \
 && mix release $RELEASE --path out

# Default Stage

FROM alpine:$ALPINE_VERSION AS default

EXPOSE 8080

WORKDIR /opt

RUN apk add --no-cache 'ncurses=~6.3' \
 && apk add --no-cache 'openssl=~1.1' \
 && apk add --no-cache 'libstdc++=~10.3'

COPY --from=release /tmp/out/ ./

ENTRYPOINT ["./bin/two_eleven"]
CMD ["start"]

