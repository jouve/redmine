FROM alpine:3.10

RUN adduser -D redmine

ARG REDMINE_VERSION=4.0.5
RUN set -e; \
    wget http://www.redmine.org/releases/redmine-${REDMINE_VERSION}.tar.gz; \
    wget http://www.redmine.org/releases/redmine-${REDMINE_VERSION}.tar.gz.md5; \
    md5sum -c redmine-${REDMINE_VERSION}.tar.gz.md5; \
    mkdir /usr/src; \
    tar xf redmine-${REDMINE_VERSION}.tar.gz -C /usr/src; \
    rm -rf redmine-${REDMINE_VERSION}.tar.gz redmine-${REDMINE_VERSION}.tar.gz.md5; \
    mv /usr/src/redmine-${REDMINE_VERSION} /usr/src/redmine; \
    echo 'config.logger = Logger.new(STDOUT)' > /usr/src/redmine/config/additional_environment.rb; \
    chown -R redmine:redmine /usr/src/redmine

WORKDIR /usr/src/redmine

ENV RAILS_ENV production

COPY --chown=redmine:redmine Gemfile.lock .

RUN set -e; \
    apk add --no-cache \
        gcc \
        imagemagick6 \
        imagemagick6-dev \
        libpq \
        make \
        musl-dev \
        postgresql-dev \
        ruby \
        ruby-bigdecimal \
        ruby-bundler \
        ruby-dev \
        ruby-etc \
        tzdata \
        zlib-dev; \
    echo '{ production: { adapter: postgresql } }' > /usr/src/redmine/config/database.yml; \
    bundle install --deployment --without develoment ldap openid test; \
    rm -f /usr/src/redmine/config/database.yml; \
    chown -R redmine:redmine .; \
    apk del --no-cache \
        gcc \
        imagemagick6-dev \
        make \
        musl-dev \
        postgresql-dev \
        ruby-dev \
        zlib-dev

COPY --chown=redmine:redmine puma.rb config
COPY docker-entrypoint.sh /usr/bin

EXPOSE 3000

USER redmine

CMD [ "docker-entrypoint.sh" ]
