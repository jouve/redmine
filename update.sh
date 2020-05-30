#!/bin/bash -x

if ! test -w /var/run/docker.sock; then
  SUDO=sudo
else
  SUDO=
fi

docker volume create apk-cache || true
docker volume create bundle-cache || true
$SUDO docker run -i -t \
  -v apk-cache:/var/cache/apk \
  -v bundle-cache:/usr/lib/ruby/gems/2.7.0/cache \
  -v $PWD:/srv \
  $(sed -n -e 's/FROM //p' Dockerfile) sh -c "
apk add --no-cache alpine-conf
setup-apkcache /var/cache/apk
export REDMINE_VERSION=4.1.1;
set -e;
wget http://www.redmine.org/releases/redmine-\${REDMINE_VERSION}.tar.gz;
mkdir /usr/src;
tar xf redmine-\${REDMINE_VERSION}.tar.gz -C /usr/src;
mv /usr/src/redmine-\${REDMINE_VERSION} /usr/src/redmine;
cd /usr/src/redmine
echo 'config.logger = Logger.new(STDOUT)' > config/additional_environment.rb;
cp /srv/Gemfile.local .
sed -i '3d' Gemfile
sed -i \"s/gem 'rails', .*/gem 'rails', '~>5.2.4.2'/\" Gemfile
export RAILS_ENV=production
apk add --no-cache gcc imagemagick6-dev libxml2-dev libxslt-dev make musl-dev postgresql-dev ruby ruby-bigdecimal ruby-bundler ruby-dev ruby-etc ruby-json tzdata zlib-dev;
echo '{ production: { adapter: postgresql } }' > config/database.yml;
bundle config --local without 'develoment test'; \
bundle config --local build.nokogiri --use-system-libraries; \
bundle install;
cp Gemfile.lock /srv
"
