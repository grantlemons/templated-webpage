FROM ghcr.io/ponylang/ponyc:release AS builder

RUN apk add --update libressl-dev

COPY *.json /src/main/
RUN corral fetch
COPY src /src/main/src
RUN corral run -- ponyc -Dlibressl -b main src

FROM alpine:latest AS runner

RUN apk add --update libressl-dev libatomic

RUN mkdir -p /app
WORKDIR /app
COPY assets /app/assets
COPY pages /app/pages
COPY --from=builder /src/main/main /app/main

EXPOSE 8443
ENTRYPOINT ["/app/main"]
