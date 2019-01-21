# frozen-string-literal: true

module SapiClient
  # Wraps an entire Sapi-NT application, such that we can walk over all of the
  # enclosed endpoint specifications to perform various operations, such as creating
  # methods we can call
  class Application
    def initialize(application_spec)
      unless File.exist?(application_spec)
        raise(SapiClient::Error, "Could not find application spec #{application_spec}")
      end

      @application_spec_file = application_spec
      @specification = YAML.load_file(application_spec)
    end

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

    def endpoint_spec_files
      Dir["#{application_spec_dir}/#{load_spec_path}/*.yaml"]
    end
  end
end
