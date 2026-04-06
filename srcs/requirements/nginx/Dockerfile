FROM alpine:3.18

RUN apk add --no-cache nginx openssl

RUN mkdir -p /etc/nginx/certs && \
    openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/certs/server.key \
    -out /etc/nginx/certs/server.crt \
    -subj "/CN=svolkau.42.fr"

COPY ./conf/nginx.conf /etc/nginx/nginx.conf

COPY ./tools/start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 443

CMD ["/start.sh"]
