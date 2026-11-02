# frozen_string_literal: true

source 'https://rubygems.org'

# git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in sapi-nt-client-ruby.gemspec
gemspec

group :development do
  gem 'bundler'
  gem 'byebug'
  gem 'minitest', '~> 5.0'
  gem 'minitest-reporters', '~> 1.0'
  gem 'mocha', '~> 2.0'
  gem 'rake'
  gem 'rubocop'
  gem 'simplecov'
  gem 'vcr', '~> 6.0'

  source 'https://rubygems.pkg.github.com/epimorphics' do
    gem 'fsa-cbd-api'
    gem 'fsa-rpa-api'
    gem 'fsa-rp-api'
  end
end
