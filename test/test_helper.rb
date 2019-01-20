# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'simplecov'

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
