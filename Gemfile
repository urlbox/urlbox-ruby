# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'http', '~> 5.0'
gem 'openssl', '~> 2.2'

group :development do
  gem 'minitest'
  gem 'rake'
  gem 'rubocop', '~> 1.23', require: false
end

group :test do
  gem 'climate_control'
  gem 'simplecov', require: false
  gem 'webmock'
end
