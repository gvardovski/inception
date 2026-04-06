FROM alpine:3.18

ARG WORDPRESS_VERSION=6.5.5
ARG WP_CLI_VERSION=2.11.0

RUN apk update && apk add --no-cache \
    php82 \
    php82-fpm \
    php82-cli \
    php82-mysqli \
    php82-json \
    php82-curl \
    php82-dom \
    php82-exif \
    php82-fileinfo \
    php82-mbstring \
    php82-openssl \
    php82-phar \
    php82-session \
    php82-xml \
    php82-tokenizer \
    mariadb-client \
    curl \
    wget \
    unzip \
    bash \
    shadow

RUN ln -sf /usr/bin/php82 /usr/bin/php
RUN ln -sf /usr/sbin/php-fpm82 /usr/sbin/php-fpm

RUN mkdir -p /var/www/wordpress

RUN curl -o /tmp/wordpress.tar.gz "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz" && \
    tar -xzf /tmp/wordpress.tar.gz -C /var/www/wordpress --strip-components=1 && \
    rm /tmp/wordpress.tar.gz

RUN curl -L "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar" \
    -o /usr/local/bin/wp && chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php82/php-fpm.d/www.conf
COPY conf/wp-config.php /etc/wordpress/wp-config.php

RUN chown -R nobody:nobody /var/www/wordpress

COPY tools/start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 9000

CMD ["/start.sh"]