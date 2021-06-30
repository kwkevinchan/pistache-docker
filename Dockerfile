FROM alpine:3.11 AS build

RUN apk add git meson g++ libressl-dev curl-dev cppcheck

WORKDIR /var/www/app

RUN git clone https://github.com/pistacheio/pistache.git ./

RUN meson setup build \
    --buildtype=release \
    -DPISTACHE_USE_SSL=true \
    -DPISTACHE_BUILD_EXAMPLES=true \
    -DPISTACHE_BUILD_TESTS=true \
    -DPISTACHE_BUILD_DOCS=false \
    --prefix=$PWD/prefix

RUN meson compile && \
    meson install -C compile && \
    meson test -C compile

COPY ./hello_server.cc /var/www/app

RUN g++ -std=c++17 ./hello_server.cc -lpistache -o server

FROM alpine:3.11 AS runtime

RUN apk add g++

WORKDIR /var/www/app

COPY --from=build /usr/local/lib/libpistache.so /usr/local/lib/libpistache.so
COPY --from=build /usr/local/lib/libpistache.so.0.0 /usr/local/lib/libpistache.so.0.0
COPY --from=build /usr/local/lib/libpistache.so.0.0.002 /usr/local/lib/libpistache.so.0.0.002
COPY --from=build /var/www/app/server /var/www/app/server

CMD /var/www/app/server