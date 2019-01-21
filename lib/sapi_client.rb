# frozen_string_literal: true

require 'yaml'
require 'sapi_client/version'
require 'sapi_client/sapi_endpoint'
require 'sapi_client/endpoint_spec'
require 'sapi_client/application'

module SapiClient
  class Error < StandardError; end
end
