FROM alpine:3.15.3

RUN adduser -D redmine

ARG REDMINE_VERSION=5.0.0
RUN set -e; \
    wget https://www.redmine.org/releases/redmine-${REDMINE_VERSION}.tar.gz; \
    wget https://www.redmine.org/releases/redmine-${REDMINE_VERSION}.tar.gz.sha256; \
    sha256sum -c redmine-${REDMINE_VERSION}.tar.gz.sha256; \
    mkdir /usr/src; \
    tar xf redmine-${REDMINE_VERSION}.tar.gz -C /usr/src; \
    rm -rf redmine-${REDMINE_VERSION}.tar.gz redmine-${REDMINE_VERSION}.tar.gz.sha256; \
    mv /usr/src/redmine-${REDMINE_VERSION} /usr/src/redmine; \
    echo 'config.logger = Logger.new(STDOUT)' > /usr/src/redmine/config/additional_environment.rb; \
    chown -R redmine:redmine /usr/src/redmine

WORKDIR /usr/src/redmine

ENV RAILS_ENV production

COPY --chown=redmine:redmine Gemfile.lock ./

RUN set -e; \
    apk add --no-cache \
        ghostscript \
        ghostscript-fonts \
        imagemagick \
        ruby \
        ruby-bigdecimal \
        ruby-bundler \
        ruby-etc \
        ruby-json \
        tzdata \
    ; \
    apk add --no-cache --virtual .build-deps \
        gcc \
        make \
        musl-dev \
        patch \
        postgresql-dev \
        ruby-dev \
        zlib-dev \
    ; \
    echo '{ production: { adapter: postgresql } }' > /usr/src/redmine/config/database.yml; \
    bundle config --local without 'develoment test'; \
    bundle config --local deployment true; \
    puma=$(sed -n /puma/p Gemfile); \
    sed -i /puma/d Gemfile; \
    echo "$puma" >> Gemfile; \
    sed -i 's/gem \"commonmarker\", .*/gem \"commonmarker\", \"~> 0.23.1\"/' Gemfile; \
    bundle install; \
    rm -f /usr/src/redmine/config/database.yml; \
    chown -R redmine:redmine .; \
    apk add --no-cache --virtual .run-deps $( \
        find /usr/src/redmine/vendor/bundle/ruby/3.0.0/extensions -name '*.so' \
        | while read -r so; do scanelf --needed --nobanner --format '%n#p' $so; done \
        | tr ',' '\n' \
        | sort -u \
        | sed 's/^/so:/' \
    ); \
    apk del --no-cache .build-deps

COPY --chown=redmine:redmine puma.rb config
COPY docker-entrypoint.sh /usr/bin

EXPOSE 3000

USER redmine

CMD [ "docker-entrypoint.sh" ]
