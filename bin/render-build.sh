#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean

# Create database if it doesn't exist
bundle exec rake db:create RAILS_ENV=production || true
bundle exec rake db:migrate