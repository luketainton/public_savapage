#!/bin/sh

set -eu

/usr/sbin/cupsd -f &
cupsd_pid=$!

stop() {
    kill "${cupsd_pid}" 2>/dev/null || true
    wait "${cupsd_pid}" 2>/dev/null || true
}

trap stop INT TERM EXIT

while ! /usr/sbin/cupsctl --remote-any >/dev/null 2>&1; do
    if ! kill -0 "${cupsd_pid}" 2>/dev/null; then
        wait "${cupsd_pid}"
        exit 1
    fi
    sleep 1
done

wait "${cupsd_pid}"
