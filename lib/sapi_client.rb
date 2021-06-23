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
require 'sapi_client/resource_wrapper'
require 'sapi_client/hierarchy_resource'
require 'sapi_client/hierarchy'

module SapiClient
  # Custom exception for wrapping API errors
  class Error < StandardError
    def initialize(message = 'Yo yo yo')
      super
    end

    def status
      msg = JSON.parse(message)
      msg['status']
    end
  end
end
