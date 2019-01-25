# frozen-string-literal: true

module SapiClient
  # Wraps an entire Sapi-NT application, such that we can walk over all of the
  # enclosed endpoint specifications to perform various operations, such as creating
  # methods we can call
  class Application
    def initialize(base_url, application_spec)
      unless File.exist?(application_spec)
        raise(SapiClient::Error, "Could not find application spec #{application_spec}")
      end

      @base_url = base_url
      @application_spec_file = application_spec
      @specification = YAML.load_file(application_spec)
    end

    attr_reader :base_url
    attr_reader :specification

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
      configuration['loadSpecPath'].sub(/^classpath:/, '')
    end

    def endpoint_group_files
      Dir["#{application_spec_dir}/#{load_spec_path}/*.yaml"]
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
    def instance
      isnt = SapiClient::Instance.new

      endpoints.each do |endpoint|
        isnt.define_singleton_method(:"#{endpoint.name}", get_items_proc(endpoint, isnt))
        isnt.define_singleton_method(:"#{endpoint.name}_json", get_json_proc(endpoint, isnt))
        isnt.define_singleton_method(:"#{endpoint.name}_spec") { endpoint }
      end

      isnt
    end

    private

    def get_items_proc(endpoint, isnt)
      proc do |options|
        endpoint_url = endpoint.url(options)
        isnt.get_items(endpoint_url, options)
      end
    end

    def get_json_proc(endpoint, isnt)
      proc do |options|
        endpoint_url = endpoint.url(options)
        isnt.get_json(endpoint_url, options)
      end
    end
  end
end
