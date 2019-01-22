# frozen-string-literal: true

module SapiClient
  # Encapsulates the specification of a collection of SAPI endpoints, and some
  # other features that are useful to the server but not to the client
  class EndpointSpec
    def initialize(base_url, spec_file_name)
      unless File.exist?(spec_file_name)
        raise(SapiClient::Error, "No such specification: #{spec_file_name}")
      end

      @specification = YAML.load_stream(File.read(spec_file_name))
      @base_url = base_url
    end

    attr_reader :specification
    attr_reader :base_url

    def endpoints
      endpoint_specs = specification.select do |spec|
        type = spec['type']
        type && SapiEndpoint::ENDPOINT_TYPES.include?(type)
      end

      endpoint_specs.map { |spec| SapiEndpoint.new(base_url, spec) }
    end

    # Returns a hash of view name to view spec object
    def views
      specification
        .select { |spec| spec['type'] == 'view' }
        .each_with_object({}) do |view_spec, hash|
          view = SapiClient::View.new(view_spec)
          hash[view.name] = view
        end
    end
  end
end
