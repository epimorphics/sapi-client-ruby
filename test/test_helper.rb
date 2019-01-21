# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'simplecov'
require 'byebug'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter
  ]
)

SimpleCov.start('rails') do
  add_filter '/test/'
end

require 'sapi_client'

require 'minitest/autorun'
require 'minitest/mock'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'test/vcr_cassettes'
  config.hook_into :faraday

  default_cassette_options = {
    record: :new_episodes
  }

  # re-record every 3 days, but only if we're running in development not CI
  # default_cassette_options[:re_record_interval] = 3.days # TODO: if Rails.env.development?

  config.default_cassette_options = default_cassette_options
end
