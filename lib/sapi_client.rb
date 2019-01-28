# frozen_string_literal: true

require 'yaml'
require 'faraday_middleware'
require 'json'
require 'logger'
require 'i18n'

require 'sapi_client/version'
require 'sapi_client/sapi_endpoint'
require 'sapi_client/endpoint_group'
require 'sapi_client/application'
require 'sapi_client/instance'
require 'sapi_client/view'
require 'sapi_client/sapi_resource'
require 'sapi_client/endpoint_values'

module SapiClient
  class Error < StandardError; end
end
