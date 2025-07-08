# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.4.4'

gem 'stackprof' # Load first for Sentry profiling

gem 'bootsnap', require: false
gem 'faraday'
gem 'importmap-rails'
gem 'jbuilder'
gem 'job-iteration'
gem 'mission_control-jobs'
gem 'propshaft'
gem 'puma'
gem 'rails', '~> 8.0'
gem 'redis'
gem 'ruby-limiter'
gem 'ruby-vips'
gem 'sentry-rails'
gem 'sentry-ruby'
gem 'solid_queue'
gem 'sqlite3'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'tzinfo-data', platforms: %i[windows jruby]

group :development, :test do
  gem 'brakeman', require: false
  gem 'debug', platforms: %i[mri windows]
  gem 'erb_lint'
  gem 'rubocop'
  gem 'rubocop-capybara'
  gem 'rubocop-rails'
end

group :development do
  gem 'ruby-lsp', require: false
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'mocha'
  gem 'selenium-webdriver'
  gem 'webmock'
end
