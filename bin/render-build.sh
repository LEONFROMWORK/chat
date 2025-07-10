#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install

# Precompile assets for production
bundle exec rake assets:precompile RAILS_ENV=production
bundle exec rake assets:clean RAILS_ENV=production

# Create database if it doesn't exist
bundle exec rake db:create RAILS_ENV=production || true
bundle exec rake db:migrate RAILS_ENV=production