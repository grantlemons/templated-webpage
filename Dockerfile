FROM ghcr.io/ponylang/ponyc:release

RUN apk add --update libressl-dev

COPY *.json /src/main/
COPY *.pony /src/main/
COPY assets /src/main/assets
COPY pages /src/main/pages

RUN corral fetch
RUN corral run -- ponyc -Dlibressl

EXPOSE 8443
ENTRYPOINT ["/src/main/main"]
