#!/bin/sh

set -eu

SERVER_HOME=/opt/savapage/server
DATA_DIR="${SERVER_HOME}/data"
DEFAULT_DATA_DIR=/opt/savapage/defaults/data
DEFAULT_CUPS_DIR=/opt/savapage/defaults/cups

mkdir -p \
    "${DATA_DIR}" \
    "${SERVER_HOME}/custom" \
    "${SERVER_HOME}/ext" \
    "${SERVER_HOME}/logs" \
    /etc/cups

# Bind mounts hide the files installed in the image. Seed them only when they
# are empty so an existing installation is never overwritten on restart.
if [ -z "$(find "${DATA_DIR}" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
    cp -a "${DEFAULT_DATA_DIR}/." "${DATA_DIR}/"
fi

if [ -z "$(find /etc/cups -mindepth 1 -maxdepth 1 -print -quit)" ]; then
    cp -a "${DEFAULT_CUPS_DIR}/." /etc/cups/
fi

chown -R savapage:savapage "${DATA_DIR}" "${SERVER_HOME}/custom" "${SERVER_HOME}/ext" "${SERVER_HOME}/logs"
chown -R root:lp /etc/cups

# Apply SP_SRV_* settings once, after the image defaults have been seeded.
# The marker prevents a restart from overwriting settings changed in the
# SavaPage administration UI or directly in server.properties.
CONFIG_MARKER="${DATA_DIR}/.savapage-env-configured"
if [ ! -e "${CONFIG_MARKER}" ]; then
    properties_tmp=$(mktemp)
    trap 'rm -f "${properties_tmp}" "${properties_tmp}.merged"' EXIT

    ns=${SAVAPAGE_NS:-SP_}
    env | while IFS= read -r line; do
        case "${line}" in
            "${ns}SRV_"*=*)
                pair=${line#*=}
                key=${pair%%:*}
                value=${pair#*:}
                [ -n "${key}" ] && printf '%s=%s\n' "${key}" "${value}" >> "${properties_tmp}"
                ;;
        esac
    done

    if [ -s "${properties_tmp}" ]; then
        awk -F= '
            NR == FNR { keys[$1] = 1; next }
            {
                split($0, fields, "=")
                if (!(fields[1] in keys)) print
            }
        ' "${properties_tmp}" "${DATA_DIR}/server.properties" > "${properties_tmp}.merged"
        cat "${properties_tmp}" >> "${properties_tmp}.merged"
        mv "${properties_tmp}.merged" "${DATA_DIR}/server.properties"
    fi

    touch "${CONFIG_MARKER}"
    chown savapage:savapage "${CONFIG_MARKER}" "${DATA_DIR}/server.properties"
fi

exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
