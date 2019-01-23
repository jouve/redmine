FROM redmine:4.0.1

COPY Gemfile.local .

RUN set -ex; \
    buildDeps=' \
        gcc \
        g++ \
        make \
        uuid-dev \
        xz-utils \
        '; \
    apt-get update && apt-get install -y $buildDeps --no-install-recommends; \
    for dbtype in mysql2 postgresql sqlite3; do \
        echo "$RAILS_ENV:" > ./config/database.yml; \
        echo "  adapter: $dbtype" >> ./config/database.yml; \
        mv "Gemfile.lock.$dbtype" Gemfile.lock; \
        bundle install --without development test; \
        mv Gemfile.lock "Gemfile.lock.$dbtype"; \
    done; \
    rm ./config/database.yml; \
    apt-get purge -y --auto-remove $buildDeps; \
	apt clean; \
    rm -rf /var/lib/apt/lists/*;

COPY config.ru ./
COPY puma.rb config/
