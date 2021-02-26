#!/bin/bash -x

if ! test -w /var/run/docker.sock; then
  SUDO=sudo
else
  SUDO=
fi

if docker container inspect cache_cache_1 &>/dev/null; then
  cache=--volumes-from=cache_cache_1
else
  cache=
fi

$SUDO docker run \
  $cache \
  --volume $PWD:/srv \
  $(head -n1 Dockerfile | sed -n -e 's/FROM //p') sh -x -c "
apk add --no-cache alpine-conf
setup-apkcache /var/cache/apk
export REDMINE_VERSION=4.1.1;
set -e;
mkdir /usr/src;
wget -O- http://www.redmine.org/releases/redmine-\${REDMINE_VERSION}.tar.gz | tar xz -C /usr/src;
mv /usr/src/redmine-\${REDMINE_VERSION} /usr/src/redmine;
cd /usr/src/redmine
echo 'config.logger = Logger.new(STDOUT)' > config/additional_environment.rb;
sed -i '3d' Gemfile
sed -i \"s/gem 'rails', .*/gem 'rails', '~>5.2.4.2'/\" Gemfile
export RAILS_ENV=production
apk add --no-cache gcc imagemagick6-dev libxml2-dev libxslt-dev linux-headers make musl-dev postgresql-dev ruby ruby-bigdecimal ruby-bundler ruby-dev ruby-etc ruby-json tzdata zlib-dev
echo '{ production: { adapter: postgresql } }' > config/database.yml
bundle config --local without 'develoment test';
bundle config --local build.nokogiri --use-system-libraries;
bundle install;
cp Gemfile.lock /srv
"
