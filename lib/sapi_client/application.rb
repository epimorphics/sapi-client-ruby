# frozen-string-literal: true

module SapiClient
  # Wraps an entire Sapi-NT application, such that we can walk over all of the
  # enclosed endpoint specifications to perform various operations, such as creating
  # methods we can call
  class Application
    def initialize(base_url, application_or_endpoints)
      unless File.exist?(application_or_endpoints)
        raise(SapiError, "Could not find application spec #{application_or_endpoints}")
      end

      @base_url = base_url
      @application_spec_file = application_or_endpoints if File.file?(application_or_endpoints)
      @endpoints_path = application_or_endpoints if File.directory?(application_or_endpoints)
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

    def endpoint_group_files
      if @endpoints_path.nil?
        Dir["#{application_spec_dir}/#{load_spec_path}/*.yaml"]
      else
        Dir["#{@endpoints_path}/*.yaml"]
      end
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
  end
end
