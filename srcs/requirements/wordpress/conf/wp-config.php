<?php

$db_name = getenv('WP_DB_NAME') ?: getenv('WORDPRESS_DB_NAME') ?: 'wordpress';
$db_user = getenv('WP_DB_USER') ?: getenv('WORDPRESS_DB_USER') ?: 'wpuser';
$db_host = getenv('WP_DB_HOST') ?: getenv('WORDPRESS_DB_HOST') ?: 'mariadb:3306';
$db_password = getenv('WP_DB_PASSWORD') ?: getenv('WORDPRESS_DB_PASSWORD') ?: '';

if ($db_password === '') {
    $db_password_file = getenv('WP_DB_PASSWORD_FILE') ?: getenv('WORDPRESS_DB_PASSWORD_FILE') ?: '/run/secrets/db_password';
    if (is_readable($db_password_file)) {
        $db_password = trim((string) file_get_contents($db_password_file));
    }
}

define('DB_NAME', $db_name);
define('DB_USER', $db_user);
define('DB_PASSWORD', $db_password);
define('DB_HOST', $db_host);
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');

$table_prefix = 'wp_';

define('WP_DEBUG', false);

if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
