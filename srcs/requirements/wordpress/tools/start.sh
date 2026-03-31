#!/bin/sh

set -eu

WP_DIR="/var/www/wordpress"
WP_CONFIG="${WP_DIR}/wp-config.php"

load_secret() {
    var_name="$1"
    file_var_name="${var_name}_FILE"
    file_path="$(eval "printf '%s' \"\${${file_var_name}:-}\"")"

    if [ -n "$file_path" ] && [ -f "$file_path" ]; then
        secret_value="$(cat "$file_path")"
        export "$var_name=$secret_value"
    fi
}

sed_escape() {
    printf '%s' "$1" | sed 's/[\/&]/\\&/g'
}

load_secret WP_DB_PASSWORD
load_secret WP_ADMIN_PASSWORD
load_secret WP_USER_PASSWORD

DB_NAME="${WP_DB_NAME:-wordpress}"
DB_USER="${WP_DB_USER:-wpuser}"
DB_PASS="${WP_DB_PASSWORD:-}"
DB_HOST="${WP_DB_HOST:-mariadb:3306}"

WP_URL="${WP_URL:-https://localhost}"
WP_TITLE="${WP_TITLE:-Inception}"
WP_ADMIN_USER="${WP_ADMIN_USER:-siteowner}"
WP_ADMIN_PASSWORD="${WP_ADMIN_PASSWORD:-}"
WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL:-siteowner@example.com}"
WP_USER_NAME="${WP_USER_NAME:-writer}"
WP_USER_PASSWORD="${WP_USER_PASSWORD:-}"
WP_USER_EMAIL="${WP_USER_EMAIL:-writer@example.com}"
WP_USER_ROLE="${WP_USER_ROLE:-author}"

WP_ADMIN_USER_LC="$(printf '%s' "${WP_ADMIN_USER}" | tr '[:upper:]' '[:lower:]')"
case "${WP_ADMIN_USER_LC}" in
    *admin*|*administrator*)
        echo "Error: WP_ADMIN_USER must not contain 'admin' or 'administrator'." >&2
        exit 1
        ;;
esac

if [ ! -f "${WP_CONFIG}" ]; then
    cp "${WP_DIR}/wp-config-sample.php" "${WP_CONFIG}"

    DB_NAME_ESC="$(sed_escape "${DB_NAME}")"
    DB_USER_ESC="$(sed_escape "${DB_USER}")"
    DB_PASS_ESC="$(sed_escape "${DB_PASS}")"
    DB_HOST_ESC="$(sed_escape "${DB_HOST}")"

    sed -i "s/database_name_here/${DB_NAME_ESC}/" "${WP_CONFIG}"
    sed -i "s/username_here/${DB_USER_ESC}/" "${WP_CONFIG}"
    sed -i "s/password_here/${DB_PASS_ESC}/" "${WP_CONFIG}"
    sed -i "s/localhost/${DB_HOST_ESC}/" "${WP_CONFIG}"

    chown nobody:nobody "${WP_CONFIG}"
fi

until wp db check --path="${WP_DIR}" --allow-root >/dev/null 2>&1; do
    sleep 2
done

if ! wp core is-installed --path="${WP_DIR}" --allow-root >/dev/null 2>&1; then
    wp core install \
        --path="${WP_DIR}" \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
fi

if wp user get "${WP_ADMIN_USER}" --field=ID --path="${WP_DIR}" --allow-root >/dev/null 2>&1; then
    wp user update "${WP_ADMIN_USER}" \
        --role=administrator \
        --user_pass="${WP_ADMIN_PASSWORD}" \
        --user_email="${WP_ADMIN_EMAIL}" \
        --path="${WP_DIR}" \
        --allow-root >/dev/null
else
    wp user create "${WP_ADMIN_USER}" "${WP_ADMIN_EMAIL}" \
        --role=administrator \
        --user_pass="${WP_ADMIN_PASSWORD}" \
        --path="${WP_DIR}" \
        --allow-root >/dev/null
fi

if ! wp user get "${WP_USER_NAME}" --field=ID --path="${WP_DIR}" --allow-root >/dev/null 2>&1; then
    wp user create "${WP_USER_NAME}" "${WP_USER_EMAIL}" \
        --role="${WP_USER_ROLE}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --path="${WP_DIR}" \
        --allow-root >/dev/null
else
    wp user update "${WP_USER_NAME}" \
        --role="${WP_USER_ROLE}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --user_email="${WP_USER_EMAIL}" \
        --path="${WP_DIR}" \
        --allow-root >/dev/null
fi

exec php-fpm82 -F
