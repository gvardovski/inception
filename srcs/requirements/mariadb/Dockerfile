FROM alpine:3.18

RUN apk update && apk add --no-cache \
    mariadb \
    mariadb-client

# Alpine default config enables skip-networking; remove it so WordPress can connect over TCP.
RUN sed -i '/^skip-networking/d' /etc/my.cnf.d/mariadb-server.cnf

RUN mkdir -p /run/mysqld \
    && chown -R mysql:mysql /run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql

COPY conf/wordpress.cnf /etc/my.cnf.d/wordpress.cnf

RUN chmod 644 /etc/my.cnf.d/wordpress.cnf

COPY tools/start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 3306

CMD ["/start.sh"]