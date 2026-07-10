FROM ghcr.io/ponylang/ponyc:release AS builder

RUN apk add --update libressl-dev

COPY *.json /src/main/
RUN corral fetch
COPY src /src/main/src
RUN corral run -- ponyc -Dlibressl -b main src

FROM alpine:latest AS runner

RUN apk add --update libressl-dev libatomic py3-pygments

RUN mkdir -p /app
WORKDIR /app
COPY crypto /app/crypto
COPY pages /app/pages
COPY public /app/public
COPY --from=builder /src/main/main /app/main

EXPOSE 80
EXPOSE 443
ENTRYPOINT ["/app/main"]
