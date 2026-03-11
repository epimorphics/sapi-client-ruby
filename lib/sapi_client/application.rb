# frozen_string_literal: true

module SapiClient
  # Wraps an entire Sapi-NT application, such that we can walk over all of the
  # enclosed endpoint specifications to perform various operations, such as creating
  # methods we can call
  class Application
    PARSED_MODEL_SPEC = {} # rubocop:disable Style/MutableConstant

    def initialize(base_url, application_or_endpoints)
      unless File.exist?(application_or_endpoints)
        raise(SapiError, "Could not find spec file/directory #{application_or_endpoints}")
      end

      @base_url = base_url
      @application_spec_file = File.file?(application_or_endpoints) ? application_or_endpoints : nil
      @endpoints_path = File.directory?(application_or_endpoints) ? application_or_endpoints : nil
      @specification = (@application_spec_file && YAML.load_file(application_or_endpoints)) || {
        'sapi-nt' => { 'config' => { 'loadSpecPath' => 'classpath:endpointSpecs' } }
      }
    end

    attr_reader :base_url, :specification

    def sapi_nt
      specification['sapi-nt']
    end

    def configuration
      sapi_nt['config']
    end

    def application_spec_dir
      File.dirname(@application_spec_file)
    end

    def load_spec_path
      @endpoints_path || configuration['loadSpecPath'].sub(/^classpath:/, '')
    end

    def final_path
      if @endpoints_path.nil?
        "#{application_spec_dir}/#{load_spec_path}/*.yaml"
      else
        "#{@endpoints_path}/*.yaml"
      end
    end

    def endpoint_group_files
      Dir[final_path]
    end

    def endpoints
      endpoint_group_files
        .map { |spec| SapiClient::EndpointGroup.new(base_url, spec) }
        .map(&:endpoints)
        .flatten
    end

    # Create an instance of this endpoint specification, which has methods
    # already defined that correspond to the endpoints in the spec. Specifically,
    # and endpoint `e` will have a methdod `e()` to get the JSON items for
    # that endpoint, and a method `e_spec()` to get the endpoint specification
    def instance # rubocop:disable Metrics/MethodLength
      inst = SapiClient::Instance.new(base_url)

      endpoints.each do |endpoint|
        inst.define_singleton_method(:"#{endpoint.name}", get_items_proc(endpoint, inst))
        inst.define_singleton_method(:"#{endpoint.name}_json", get_json_proc(endpoint, inst))
        inst.define_singleton_method(:"#{endpoint.name}_spec") { endpoint }
        if endpoint.hierarchy_endpoint? # rubocop:disable Style/Next
          inst.define_singleton_method(
            :"#{endpoint.name}_hierarchy",
            get_hierarchy_proc(endpoint, inst)
          )
        end
      end

      inst
    end

    private

    def get_items_proc(endpoint, inst)
      proc do |options|
        options[:wrapper] ||= endpoint.resource_type_wrapper_class
        endpoint_url = endpoint.url(options)
        inst.get_items(endpoint_url, options)
      end
    end

    def get_json_proc(endpoint, inst)
      proc do |options|
        endpoint_url = endpoint.url(options)
        inst.get_json(endpoint_url, options)
      end
    end

    def get_hierarchy_proc(endpoint, inst)
      proc do |options, scheme|
        options[:_all] = true unless options.key?(:_all)
        endpoint_url = endpoint.url(options)
        inst.get_hierarchy(endpoint_url, options, scheme)
      end
    end

    # Parses the API model spec file and populates Hash with resulting class names and properties
    def parse_model_spec # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      # Load model spec file
      model_spec = final_path.gsub('/*.yaml', '/model.yaml')
      m = YAML.load_file(model_spec)

      # Parse class names and prefixes
      qname2local = {}
      m['classes'].each do |cls|
        qname2local[cls['class']] = cls['name']
      end
      prefix2uri = m['prefixes']
      builtins = {
        'http://www.w3.org/1999/02/22-rdf-syntax-ns#langString' => 'String',
        'http://www.w3.org/2001/XMLSchema#string' => 'String',
        'http://www.w3.org/2000/01/rdf-schema#Literal' => 'String',
        'http://www.w3.org/2001/XMLSchema#boolean' => 'bool',
        'http://www.w3.org/2001/XMLSchema#date' => 'Date',
        'http://www.w3.org/2001/XMLSchema#dateTime' => 'DateTime',
        'http://www.w3.org/2001/XMLSchema#integer' => 'Integer',
        'http://www.w3.org/2001/XMLSchema#decimal' => 'BigDecimal',
        'http://www.w3.org/2001/XMLSchema#double' => 'Float'
      }

      # Parse classes and properties and populate PARSED_MODEL_SPEC
      m['classes'].each do |cls|
        # Skip if class has already been parsed
        next if PARSED_MODEL_SPEC.keys.include?(type2fulltype(cls['class'], prefix2uri))

        # If not, parse class and properties
        PARSED_MODEL_SPEC[type2fulltype(cls['class'], prefix2uri)] = {}
        cls['properties'].each do |prop|
          ts = Set.new

          if prop['type'].is_a?(Array)
            prop['type'].each do |t|
              ts << type2ruby(t, prefix2uri, qname2local, builtins)
            end
          else
            ts << type2ruby(prop['type'], prefix2uri, qname2local, builtins)
          end
          ts << 'nil' if prop['optional']

          PARSED_MODEL_SPEC[type2fulltype(cls['class'], prefix2uri)][prop['name']] = returns(ts)
          snake_prop = to_underscore(prop['name'])
          if snake_prop != prop['name']
            PARSED_MODEL_SPEC[type2fulltype(cls['class'], prefix2uri)][snake_prop] =
              returns(ts)
          end
        end
      end

      nil
    end

    # Helper method for parsing model spec file
    def type2fulltype(typ, prefix2uri)
      spl = typ.split(':')
      pref = prefix2uri[spl[0]]
      pref + spl[1]
    rescue StandardError
      typ
    end

    # Helper method for parsing model spec file
    def type2ruby(typ, prefix2uri, qname2local, builtins)
      full_uri = type2fulltype(typ, prefix2uri)
      if qname2local.include? typ
        qname2local[typ]
      elsif builtins.include? full_uri
        builtins[full_uri]
      else
        'String'
      end
    rescue StandardError
      'String'
    end

    # Helper method for parsing model spec file
    def returns(types)
      if types.size > 1
        "( #{types.join(' | ')} )"
      elsif types.size == 1
        types.first
      else
        'untyped'
      end
    end

    # Helper method for parsing model spec file
    def to_underscore(string)
      string.gsub('::', '/')
            .gsub(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .tr('-', '_')
            .downcase
    end
  end
end
