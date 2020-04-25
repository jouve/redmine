#!/bin/bash -x

docker run -v $PWD:/srv $(sed -n -e 's/FROM //p' Dockerfile) sh -c "
export REDMINE_VERSION=4.1.1;
set -e;
wget http://www.redmine.org/releases/redmine-\${REDMINE_VERSION}.tar.gz;
mkdir /usr/src; 
tar xf redmine-\${REDMINE_VERSION}.tar.gz -C /usr/src; 
mv /usr/src/redmine-\${REDMINE_VERSION} /usr/src/redmine; 
echo 'config.logger = Logger.new(STDOUT)' > /usr/src/redmine/config/additional_environment.rb; 
cp /srv/Gemfile.local /usr/src/redmine
cd /usr/src/redmine
export RAILS_ENV=production
apk add --no-cache gcc imagemagick6 imagemagick6-dev libpq make musl-dev postgresql-dev ruby ruby-bigdecimal ruby-bundler ruby-dev ruby-etc ruby-json tzdata zlib-dev; 
echo '{ production: { adapter: postgresql } }' > /usr/src/redmine/config/database.yml; 
bundle install --without develoment test; 
cp /usr/src/redmine/Gemfile.lock /srv
"
