# frozen-string-literal: true

module SapiClient
  # Encapsulates the specification of a group of SAPI endpoints, and some
  # other features that are useful to the server but not to the client
  class EndpointGroup
    def initialize(base_url, spec_file_name)
      unless File.exist?(spec_file_name)
        raise(SapiError, "No such specification file: #{spec_file_name}")
      end

      @specification = YAML.load_stream(File.read(spec_file_name))
      @base_url = base_url
    end

    attr_reader :specification, :base_url

    def endpoints
      endpoint_specs = []

      specification.each do |spec|
        if spec['type'] == 'view'
          ViewRegistry.register(SapiClient::View.new(spec))
        elsif SapiEndpoint::ENDPOINT_TYPES.include?(spec['type'])
          endpoint_specs << SapiEndpoint.new(base_url, spec)
        end
      end

      endpoint_specs
    end
  end
end
