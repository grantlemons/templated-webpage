FROM ghcr.io/ponylang/ponyc:release

RUN apk add --update libressl-dev

COPY *.json /src/main/
RUN corral fetch

COPY src /src/main/src
RUN corral run -- ponyc -Dlibressl -b main src

COPY assets /src/main/assets
COPY pages /src/main/pages

EXPOSE 8443
ENTRYPOINT ["/src/main/main"]
