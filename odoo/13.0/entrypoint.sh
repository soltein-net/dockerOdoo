#!/bin/bash

set -e

# Ensure we're using the virtualenv
source /opt/venv/bin/activate

echo "Python path: $(which python3)"
echo "Python version: $(python3 --version)"
echo "Pip version: $(pip --version)"

if [ -v PASSWORD_FILE ]; then
    PASSWORD="$(< $PASSWORD_FILE)"
fi

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" |cut -d " " -f3|sed 's/["\n\r]//g')
    fi;
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec python3 /opt/odoo13.0/odoo-bin "$@"
        else
            # shellcheck disable=SC2068
            wait-for-psql.py ${DB_ARGS[@]} --timeout=30
            exec python3 /opt/odoo13.0/odoo-bin "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        # shellcheck disable=SC2068
        wait-for-psql.py ${DB_ARGS[@]} --timeout=30
        exec python3 /opt/odoo13.0/odoo-bin "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1