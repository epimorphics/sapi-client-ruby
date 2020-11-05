# frozen-string-literal: true

module SapiClient
  # Denotes a single SAPI-NT endpoint, which we can call to get back JSON data
  # about some domain value. An endpoint has a one-to-one correspondance with a
  # particular API path
  class SapiEndpoint
    DEP_ENDPOINT_TYPE_LIST = 'list'
    DEP_ENDPOINT_TYPE_ITEM = 'item'
    DEP_ENDPOINT_TYPE_FORWARD = 'forward'
    ENDPOINT_TYPE_LIST = 'endpoint.list'
    ENDPOINT_TYPE_ITEM = 'endpoint.item'
    ENDPOINT_TYPE_FORWARD = 'endpoint.forward'
    ENDPOINT_TYPES = [
      DEP_ENDPOINT_TYPE_LIST, DEP_ENDPOINT_TYPE_ITEM, DEP_ENDPOINT_TYPE_FORWARD,
      ENDPOINT_TYPE_LIST, ENDPOINT_TYPE_ITEM, ENDPOINT_TYPE_FORWARD
    ].freeze

    def initialize(base_url, views_register, specification)
      raise(SapiClient::Error, 'Missing specification type') unless specification.key?('type')

      @base_url = base_url
      @views_register = views_register
      @specification = specification
      @type = specification['type']
      return if ENDPOINT_TYPES.include?(@type)

      raise(SapiClient::Error, "Unknown endpoint type: #{@type}")
    end

    attr_reader :base_url, :specification, :views_register

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
        .tr('-.', '_')
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

    def path(options) # rubocop:disable Metrics/AbcSize
      path_variables(raw_path)
        .reduce(raw_path) do |pth, path_var|
          var_name = path_var[:name]
          var_name = var_name.to_sym if !options[var_name] && options[var_name.to_sym]

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
      views.keys
    end

    def named_view(name)
      views_register[name]
    end

    # @return A hash of all of the known views to the view specifications
    def views
      if specification['view']
        { 'default' => specification['view'] }
      else
        specification['views'] || {}
      end
    end

    # @return The view object named by the given key. Use `'default'` for the default view
    def view(name = 'default')
      return nil unless (view = views[name])

      view.is_a?(String) ? named_view(view) : SapiClient::View.new('view' => view)
    end

    # We take the resource type of the endpoint to be the resource type of the default
    # view, if defined
    def resource_type
      view&.resource_type
    end

    # Introspect whether there is a wrapper class that can be used to encapsulate
    # values coming back from this endpoint
    # @return A class corresponding to the `resource_type`, if defined, or nil
    def resource_type_wrapper_class
      ResourceWrapper.find_wrapper_type(resource_type) if resource_type
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
