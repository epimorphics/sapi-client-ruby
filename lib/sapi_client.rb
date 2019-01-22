# frozen_string_literal: true

require 'yaml'
require 'faraday_middleware'
require 'json'

require 'sapi_client/version'
require 'sapi_client/sapi_endpoint'
require 'sapi_client/endpoint_spec'
require 'sapi_client/application'
require 'sapi_client/instance'

module SapiClient
  class Error < StandardError; end
end
