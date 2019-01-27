# frozen-string-literal: true

module SapiClient
  # Denotes a single SAPI-NT endpoint, which we can call to get back JSON data
  # about some domain value. An endpoint has a one-to-one correspondance with a
  # particular API path
  class SapiEndpoint
    ENDPOINT_TYPE_LIST = 'list'
    ENDPOINT_TYPE_ITEM = 'item'
    ENDPOINT_TYPES = [ENDPOINT_TYPE_LIST, ENDPOINT_TYPE_ITEM].freeze

    def initialize(base_url, views, specification)
      raise(SapiClient::Error, 'Missing specification type') unless specification.key?('type')

      @base_url = base_url
      @views = views
      @specification = specification
      @type = specification['type']
      return if ENDPOINT_TYPES.include?(@type)

      raise(SapiClient::Error, "Unknown endpoint type: #{@type}")
    end

    attr_reader :base_url
    attr_reader :specification
    attr_reader :views

    def item_endpoint?
      @type == ENDPOINT_TYPE_ITEM
    end

    def list_endpoint?
      @type == ENDPOINT_TYPE_LIST
    end

    # The name of the endpoint is based on the configured name from the Sapi-NT spec,
    # but we adopt Ruby case conventions
    def name
      specification['name']
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr('-', '_')
        .downcase
    end

    def description
      specification['description']
    end

    def raw_path
      specification['url']
    end

    def path_variables(path)
      path
        .scan(/{[^}]+}/)
        .map do |match|
          {
            substitution: match,
            name: match[1..-2].sub(/^_*/, '')
          }
        end
    end

    def path(options)
      path_variables(raw_path)
        .reduce(raw_path) do |pth, path_var|
          var_name = path_var[:name]
          unless options[var_name]
            raise(SapiClient::Error, "Missing #{var_name} for endpoint path: #{raw_path}}")
          end

          pth.sub(path_var[:substitution], options.delete(var_name).to_s)
        end
    end

    def url(options)
      "#{base_url}#{path(options)}"
    end

    def view_names
      specification['views']&.keys
    end

    def view(name)
      view_key = specification['views']&.[](name)
      view_key && views[view_key]
    end

    # We take the resource type of the endpoint to be the resource type of the default
    # view, if defined
    def resource_type
      view('default')&.resource_type
    end

    # Introspect whether there is a wrapper class that can be used to encapsulate
    # values coming back from this endpoint
    # @return A class corresponding to the `resource_type`, if defined, or nil
    def resource_type_wrapper_class
      if (rtype = resource_type)
        if rtype.respond_to?(:classify)
          # if we're in Rails-land, this is a better way
          rtype.classify.constantize
        else
          Kernel.const_get(rtype)
        end
      end
    rescue NameError => _e
      SapiClient::SapiResource
    end

    # Bind the given array of variable values to the path variable names
    def bind(options, arg_values)
      vars = path_variables(raw_path)
      if vars.length != arg_values.length
        raise(SapiClient::Error, "Mismatched args to bind: #{vars.inspect} / #{arg_values.inspect}")
      end

      vars.zip(arg_values).each do |var_name, value|
        options[var_name[:name]] = value
      end

      options
    end
  end
end
