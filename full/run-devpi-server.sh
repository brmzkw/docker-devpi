#!/bin/sh


if [ "$1" != "bg" ]; then
    devpi-server --host 0.0.0.0 --port 4040 --serverdir /var/lib/devpi
    exit
fi


devpi-server --host 0.0.0.0 --port 4040 --serverdir /var/lib/devpi >/var/log/devpi.log 2>/var/log/devpi.log &


# Wait until the server is up before returning.
while true;
do
    curl -s localhost:4040 >/dev/null && break
    sleep 1
done
