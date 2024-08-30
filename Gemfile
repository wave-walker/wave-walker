# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.3.1'

gem 'stackprof' # Load first for Sentry profiling

gem 'bootsnap', require: false
gem 'faraday'
gem 'good_job'
gem 'importmap-rails'
gem 'jbuilder'
gem 'job-iteration'
gem 'pg'
gem 'propshaft'
gem 'puma'
gem 'rails', '~> 7.2.1'
gem 'redis'
gem 'ruby-limiter'
gem 'ruby-vips'
gem 'sentry-rails'
gem 'sentry-ruby'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'tzinfo-data', platforms: %i[windows jruby]

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows]
  gem 'erb_lint'
  gem 'rubocop'
  gem 'rubocop-capybara'
  gem 'rubocop-rails'
end

group :development do
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'mocha'
  gem 'selenium-webdriver'
  gem 'webmock'
end
