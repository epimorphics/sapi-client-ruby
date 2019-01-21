# frozen-string-literal: true

module SapiClient
  # Encapsulates the specification of a collection of SAPI endpoints, and some
  # other features that are useful to the server but not to the client
  class EndpointSpec
    def initialize(spec_file_name)
      @specification = YAML.load_file(spec_file_name)
    rescue Errno::ENOENT
      raise(SapiClient::Error, "No such specification file: #{spec_file_name}")
    end

    attr_reader :specification

    def endpoints
      endpoint_specs = specification.select do |spec|
        byebug
        type = spec['type']
        type && SapiEndpoint::ENDPOINT_TYPES.include?(type)
      end

      endpoint_specs.map { |spec| SapiEndpoint.new(spec) }
    end
  end
end
