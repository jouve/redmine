#!/bin/sh

if [ ! -f config/database.yml ]; then
  cat <<EOF > config/database.yml
production:
  adapter: postgresql
  host: ${REDMINE_DB_HOST:-"db"}
  database: ${REDMINE_DB_DATABASE:-"redmine"}
  username: ${REDMINE_DB_USERNAME:-"redmine"}
  password: ${REDMINE_DB_PASSWORD:-"redmine"}
  encoding: utf8
EOF
fi

if [ ! -f config/initializers/secret_token.rb ]; then
  if [ -z "${REDMINE_SECRET_TOKEN}" ]; then
    bundle exec rake generate_secret_token
  else
    echo "RedmineApp::Application.config.secret_key_base = '$REDMINE_SECRET_TOKEN'" > config/initializers/secret_token.rb
  fi
fi

if [ "${REDMINE_DB_MIGRATE:-"1"}" == "1" ]; then
  bundle exec rake db:migrate
  bundle exec rake redmine:plugins:migrate
fi

exec bundle exec rails s
