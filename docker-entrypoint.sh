#!/bin/sh

if [ ! -f config/database.yml ]; then
  cat <<EOF > config/database.yml
production:
  adapter: postgresql
  host: db
  database: ${REDMINE_DB_DATABASE:-"redmine"}
  username: ${REDMINE_DB_USERNAME:-"redmine"}
  password: ${REDMINE_DB_PASSWORD:-"redmine"}
  encoding: utf8
EOF
fi

if [ ! -f config/initializers/secret_token.rb ]; then
  bin/rake generate_secret_token
fi

if [ "${REDMINE_DB_MIGRATE:-"1"}" == "1" ]; then
  bin/rake db:migrate
  bin/rake redmine:plugins:migrate
fi

exec bin/rails s
