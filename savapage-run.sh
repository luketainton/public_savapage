#!/bin/sh

set -eu

APP_SERVER=/opt/savapage/server/bin/linux-x64/app-server
PID_FILE=/opt/savapage/server/logs/service.pid

"${APP_SERVER}" start

if [ ! -s "${PID_FILE}" ]; then
    echo "SavaPage did not create ${PID_FILE}" >&2
    exit 1
fi

pid=$(cat "${PID_FILE}")

stop() {
    "${APP_SERVER}" stop >/dev/null 2>&1 || true
}

trap stop INT TERM EXIT

while kill -0 "${pid}" 2>/dev/null; do
    sleep 2
done

exit 1
