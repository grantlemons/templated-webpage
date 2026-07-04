FROM ghcr.io/ponylang/ponyc:release

RUN apk add --update libressl-dev

COPY *.json /src/main/
COPY src /src/main/src
COPY assets /src/main/assets
COPY pages /src/main/pages

RUN corral fetch
RUN corral run -- ponyc -Dlibressl -b main src

EXPOSE 8443
ENTRYPOINT ["/src/main/main"]
