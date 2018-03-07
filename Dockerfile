FROM redmine:3.4.4

RUN buildDeps=' \
		curl \
		' \
	&& set -ex \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get purge -y --auto-remove $buildDeps

COPY Gemfile.local .

RUN buildDeps=' \
		gcc \
		g++ \
		make \
		uuid-dev \
		xz-utils \
		' \
	&& set -ex \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/* \
	&& echo "$RAILS_ENV:" > ./config/database.yml \
	&& echo "  adapter: mysql2" >> ./config/database.yml \
	&& mv Gemfile.lock.mysql2 Gemfile.lock \
	&& bundle install --without development test \
	&& mv Gemfile.lock Gemfile.lock.mysql2 \
	&& rm ./config/database.yml \
	&& apt-get purge -y --auto-remove $buildDeps

COPY additional_environment.rb config/

