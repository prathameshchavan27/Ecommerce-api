#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -o errexit

# Install Ruby gems from Gemfile.lock
bundle install

# Precompile assets
bundle exec rails assets:precompile

# Run database migrations
bundle exec rails db:migrate