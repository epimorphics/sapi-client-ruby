# frozen-string-literal: true

module SapiClient
  # Denotes a single SAPI-NT endpoint, which we can call to get back JSON data
  # about some domain value. An endpoint has a one-to-one correspondance with a
  # particular API path
  class SapiEndpoint
    ENDPOINT_TYPE_LIST = 'list'
    ENDPOINT_TYPE_ITEM = 'item'
    ENDPOINT_TYPES = [ENDPOINT_TYPE_LIST, ENDPOINT_TYPE_ITEM].freeze

    def initialize(base_url, specification)
      raise(SapiClient::Error, 'Missing specification type') unless specification.key?('type')

      @base_url = base_url
      @specification = specification
      @type = specification['type']
      return if ENDPOINT_TYPES.include?(@type)

      raise(SapiClient::Error, "Unknown endpoint type: #{@type}")
    end

    attr_reader :base_url

    def item_endpoint?
      @type == ENDPOINT_TYPE_ITEM
    end

    def list_endpoint?
      @type == ENDPOINT_TYPE_LIST
    end

    def raw_path
      @specification['url']
    end

    def path
      # TODO
      raw_path
    end

    def url
      "#{base_url}#{path}"
    end
  end
end
