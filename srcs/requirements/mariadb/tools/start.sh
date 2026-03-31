#!/bin/sh

set -eu

DB_DIR="/var/lib/mysql"
DB_SOCKET="/run/mysqld/mysqld.sock"

load_secret() {
    var_name="$1"
    file_var_name="${var_name}_FILE"
    file_path="$(eval "printf '%s' \"\${${file_var_name}:-}\"")"

    if [ -n "$file_path" ] && [ -f "$file_path" ]; then
        secret_value="$(cat "$file_path")"
        export "$var_name=$secret_value"
    fi
}

sql_escape() {
    printf "%s" "$1" | sed "s/'/''/g"
}

load_secret MYSQL_ROOT_PASSWORD
load_secret MYSQL_PASSWORD

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld "$DB_DIR"

FIRST_INIT=0
if [ ! -d "${DB_DIR}/mysql" ]; then
    FIRST_INIT=1
    mariadb-install-db --user=mysql --datadir="${DB_DIR}" >/dev/null
fi

if [ "${FIRST_INIT}" -eq 1 ]; then
    DB_NAME="${MYSQL_DATABASE:-wordpress}"
    DB_USER="${MYSQL_USER:-wpuser}"
    DB_PASS="${MYSQL_PASSWORD:-}"
    DB_USER_ESC="$(sql_escape "${DB_USER}")"
    DB_PASS_ESC="$(sql_escape "${DB_PASS}")"
    ROOT_PASS_ESC="$(sql_escape "${MYSQL_ROOT_PASSWORD:-}")"

    mariadbd --user=mysql --datadir="${DB_DIR}" --socket="${DB_SOCKET}" --skip-networking &
    TEMP_PID=$!

    while ! mariadb-admin --socket="${DB_SOCKET}" ping >/dev/null 2>&1; do
        sleep 1
    done

    mariadb --socket="${DB_SOCKET}" << EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER_ESC}'@'%' IDENTIFIED BY '${DB_PASS_ESC}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER_ESC}'@'%';
FLUSH PRIVILEGES;
EOF

    if [ -n "${MYSQL_ROOT_PASSWORD:-}" ]; then
        mariadb --socket="${DB_SOCKET}" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS_ESC}';"
        mariadb --socket="${DB_SOCKET}" -e "FLUSH PRIVILEGES;"
        mariadb-admin --socket="${DB_SOCKET}" --user=root --password="${MYSQL_ROOT_PASSWORD}" shutdown
    else
        mariadb-admin --socket="${DB_SOCKET}" shutdown
    fi
    wait "${TEMP_PID}" || true
fi

exec mariadbd --user=mysql --datadir="${DB_DIR}" --socket="${DB_SOCKET}" --bind-address=0.0.0.0
