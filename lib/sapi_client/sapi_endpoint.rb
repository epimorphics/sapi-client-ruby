# frozen-string-literal: true

module SapiClient
  # Denotes a single SAPI-NT endpoint, which we can call to get back JSON data
  # about some domain value. An endpoint has a one-to-one correspondance with a
  # particular API path
  class SapiEndpoint
    ENDPOINT_TYPE_LIST = 'list'
    ENDPOINT_TYPE_ITEM = 'item'
    ENDPOINT_TYPES = [ENDPOINT_TYPE_LIST, ENDPOINT_TYPE_ITEM].freeze

    def initialize(specification)
      raise(SapiClient::Error, 'Missing specification type') unless specification.key?(:type)

      @specification = specification
      @type = specification[:type]
      return if ENDPOINT_TYPES.include?(@type)

      raise(SapiClient::Error, "Unknown endpoint type: #{@type}")
    end
  end
end
