FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build-env
WORKDIR /app
COPY ["./docker.csproj", "./"]
RUN dotnet restore
WORKDIR /app/docker
COPY . .
RUN ls -ltr
RUN dotnet publish -c Release -o out
FROM mcr.microsoft.com/dotnet/aspnet:6.0

WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive
ENV ASPNETCORE_URLS http://*:5000

COPY --from=build-env /app/docker/out .

RUN apt-get update \
    && apt-get -q -y --no-install-recommends install \
    curl \
    dovecot-imapd \
    nginx \
    php \
    php-fpm \
    php-imap \
    php-mbstring \
    php-pear \
    php-sqlite3 \
    php-zip \
    postfix \
    roundcube \
    roundcube-plugins \
    roundcube-plugins-extra \
    roundcube-sqlite3 \
    rsyslog \
    sqlite3 \
    ssl-cert \
    telnet \
    && rm -rf /var/lib/apt/lists/*

ENV MAILTRAP_USER mailtrap
ENV MAILTRAP_PASSWORD mailtrap
ENV MAILTRAP_MAILBOX_LIMIT 51200000
ENV MAILTRAP_MESSAGE_LIMIT 10240000
ENV MAILTRAP_MAX_RECIPIENT_LIMIT 1000

# Avoid kernel logging
RUN sed -i '/imklog/s/^/#/' /etc/rsyslog.conf

# Postfix
COPY root/etc/postfix/* /etc/postfix/

# Dovecot
COPY root/etc/dovecot/conf.d/* /etc/dovecot/conf.d/
RUN groupadd -g 5000 vmail
RUN useradd -g vmail -u 5000 vmail -d /var/mail/vmail -m
RUN usermod -a -G dovecot postfix

# NGINX
COPY root/etc/nginx/sites-available/roundcube /etc/nginx/sites-available/
RUN rm /etc/nginx/sites-enabled/default && \
    ln -s /etc/nginx/sites-available/roundcube /etc/nginx/sites-enabled/roundcube

# Roundcube
COPY root/etc/roundcube/config.inc.php etc/roundcube/config.inc.php
RUN mkdir -p /var/lib/roundcube/db && \
    sqlite3 -init /usr/share/roundcube/SQL/sqlite.initial.sql /var/lib/roundcube/db/sqlite.db && \
    chmod 775 -R /var/lib/roundcube/db && \
    chown -R www-data:www-data /var/lib/roundcube/db

# API
COPY root/usr/share/roundcube/api.php /usr/share/roundcube/

COPY root/docker-entrypoint.sh .
RUN chmod 777 ./docker-entrypoint.sh


ENTRYPOINT [ "./docker-entrypoint.sh" ]

EXPOSE 25 80 465 587 143 993 5000 1234
