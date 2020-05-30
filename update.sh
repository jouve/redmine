#!/bin/bash -x

if ! test -w /var/run/docker.sock; then
  SUDO=sudo
else
  SUDO=
fi

docker volume create apk-cache || true
$SUDO docker run -i -t \
  -v pip-cache:/root/.cache/pip \
  -v pipenv-cache:/root/.cache/pipenv \
  -v apk-cache:/var/cache/apk \
  -v $PWD:/srv \
  $(sed -n -e 's/FROM //p' Dockerfile) sh -c "
export REDMINE_VERSION=4.1.1;
set -e;
wget http://www.redmine.org/releases/redmine-\${REDMINE_VERSION}.tar.gz;
mkdir /usr/src;
tar xf redmine-\${REDMINE_VERSION}.tar.gz -C /usr/src;
mv /usr/src/redmine-\${REDMINE_VERSION} /usr/src/redmine;
echo 'config.logger = Logger.new(STDOUT)' > /usr/src/redmine/config/additional_environment.rb;
cp /srv/Gemfile.local /usr/src/redmine
cd /usr/src/redmine
sed -i '3d' Gemfile
export RAILS_ENV=production
apk add --no-cache gcc imagemagick6 imagemagick6-dev libpq make musl-dev postgresql-dev ruby ruby-bigdecimal ruby-bundler ruby-dev ruby-etc ruby-json tzdata zlib-dev;
echo '{ production: { adapter: postgresql } }' > /usr/src/redmine/config/database.yml;
bundle config set without 'develoment ldap test openid';
bundle install;
cp /usr/src/redmine/Gemfile.lock /srv
"
