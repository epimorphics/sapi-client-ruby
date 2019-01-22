# frozen_string_literal: true

require 'yaml'
require 'faraday_middleware'
require 'json'
require 'logger'

require 'sapi_client/version'
require 'sapi_client/sapi_endpoint'
require 'sapi_client/endpoint_spec'
require 'sapi_client/application'
require 'sapi_client/instance'
require 'sapi_client/view'

module SapiClient
  class Error < StandardError; end
end
