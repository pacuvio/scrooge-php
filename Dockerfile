FROM alpine:edge

RUN set -xe; \
    \
    apk --update add tini php7 php7-fpm php7-dom php7-curl php7-phar \
        php7-pdo_mysql php7-pdo_sqlite php7-xml php7-mbstring php7-iconv \
        php7-posix php7-pdo php7-json php7-session php7-ctype php7-tokenizer \
        php7-simplexml php7-zlib php7-mcrypt php7-intl php7-mysqli php7-opcache \
        php7-apcu php7-xdebug; \
    \
    addgroup -g 1000 -S www-data; \
    adduser -u 1000 -D -S -G www-data www-data; \
    echo "date.timezone = \"Europe/Rome\"" > /etc/php7/conf.d/date.ini; \
    mkdir /var/www && chown www-data:www-data /var/www

ADD https://getcomposer.org/composer.phar /bin/composer
ADD www.conf /etc/php7/php-fpm.d/www.conf

RUN chown www-data:www-data /bin/composer && chmod ug+rwx /bin/composer

ENTRYPOINT ["tini", "--"]

WORKDIR /var/www

CMD ["php-fpm7", "-F"]
