FROM alpine:3.7

ARG IMAGE_VERSION
ARG BUILD_DATE
ARG VCS_REF

ENV GLPI_SOURCE_URL="https://github.com/glpi-project/glpi/releases/download/9.2.4/glpi-9.2.4.tgz" \
    GLPI_PATHS_ROOT="/var/www" \
    GLPI_PATHS_PLUGINS="/var/www/plugins" \
    GLPI_REMOVE_INSTALLER=no \
    GLPI_CHMOD_FILES=no \
    GLPI_INSTALL_PLUGINS="fusioninventory|https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.3%2B1.0/fusioninventory-9.3.1.0.tar.bz2"

LABEL maintainer="Pierre GINDRAUD <pgindraud@gmail.com>" \
      org.label-schema.build-date="${BUILD_DATE}" \
      org.label-schema.name="Web application GLPI in docker" \
      org.label-schema.description="This image contains the GLPI web application" \
      org.label-schema.url="https://github.com/Turgon37/docker-glpi" \
      org.label-schema.vcs-ref="${VCS_REF}" \
      org.label-schema.vcs-url="https://github.com/Turgon37/docker-glpi" \
      org.label-schema.vendor="Pierre GINDRAUD" \
      org.label-schema.version="${IMAGE_VERSION}" \
      org.label-schema.schema-version="1.0" \
      image.version="${IMAGE_VERSION}"

# Install dependencies
RUN apk --no-cache add \
      curl \
      nginx \
      php5 \
      php5-curl \
      php5-ctype \
      php5-dom \
      php5-fpm \
      php5-gd \
      php5-imap \
      php5-json \
      php5-ldap \
      php5-pdo_mysql \
      php5-mysqli \
      php5-openssl \
      php5-opcache \
      php5-xml \
      php5-xmlrpc \
      php5-zlib \
      supervisor \
      tar && \
    apk --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.5/main/ add \
      php5-apcu && \
# Install GLPI sources
  echo '-----------> Install GLPI' && \
  echo "Using ${GLPI_SOURCE_URL}" && \
  mkdir -p /run/nginx && \
  mkdir -p "${GLPI_PATHS_ROOT}" && \
  adduser -h "${GLPI_PATHS_ROOT}" -g 'Web Application User' -S -D -H -G www-data www-data && \
  cd "${GLPI_PATHS_ROOT}" && \  
  curl -o glpi.tar.gz -L ${GLPI_SOURCE_URL} && \
  tar -xzf glpi.tar.gz --strip 1 && \
  rm "glpi.tar.gz"  && \
  rm -rf AUTHORS.txt CHANGELOG.txt LISEZMOI.txt README.md


# Add some configurations files
COPY root/ /

# Apply PHP FPM configuration
RUN sed -i -e "s|;daemonize\s*=\s*yes|daemonize = no|g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|display_errors = Off|display_errors = stderr|" /etc/php5/php.ini && \
    sed -i -e "s|display_startup_errors = Off|display_startup_errors = On|" /etc/php5/php.ini && \
    sed -i -e "s|user\s*=\s*nobody|user = www-data|g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|group\s*=\s*nobody|group = www-data|g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|listen\s*=\s*127\.0\.0\.1:9000|listen = /var/run/php-fpm5.sock|g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|;listen\.owner\s*=\s*.*$|listen.owner = www-data|g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|;listen\.group\s*=.*$|listen.group = nginx|g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|;listen\.mode\s*=\s*|listen.mode = |g" /etc/php5/php-fpm.conf && \
    sed -i -e "s|max_execution_time\s*=.*$|max_execution_time = 600|" /etc/php5/php.ini && \
    sed -i -e "s|upload_max_filesize\s*=.*$|upload_max_filesize = 30M|" /etc/php5/php.ini && \
    chown -R www-data:www-data /var/www && \
    chmod -R g=rX,o=--- /var/www

EXPOSE 80/tcp
VOLUME ["/var/www/files", "/var/www/config"]
WORKDIR "${GLPI_PATHS_ROOT}"

HEALTHCHECK --interval=5s --timeout=3s --retries=3 \
    CMD curl --silent --fail http://localhost:80 || exit 1

CMD ["/start.sh"]
