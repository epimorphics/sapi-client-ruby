# frozen-string-literal: true

require 'logger'
require 'byebug'

module SapiClient
  # Denotes a particular instance of a Sapi-NT API. The instance has the basic
  # capability of invoking a generic endpoint by URL, and we the augment this
  # instance by generating methods that can be used to invoke endpoints based
  # on the application specification.
  #
  # If the `request_logger` is set, each request and response pair is sent to the
  # just before the request is made and just after the response is received.
  class Instance
    def initialize(base_url)
      @base_url = base_url
    end

    attr_accessor :request_logger, :base_url

    # Get the resource items from the given endpoint, but then
    # post-process them to create a resource hierarchy using
    # some hierarchy-encoding scheme such as `:skos`
    def get_hierarchy(url, options, scheme)
      Hierarchy.new(get_items(url, options), scheme)
    end

    def get_items(url, options = {})
      wrapper = options.delete(:wrapper)
      raise(SapiClient::Error, "Unexpected relative URL #{url}") unless absolute_url?(url)

      json = get_json(url, options)
      items = json['error'] ? [json] : json['items'] || []

      wrapper ? items.map { |item| wrapper.new(item) } : items
    end

    # Get parsed JSON from the given URL
    def get_json(url, options = {})
      JSON.parse(get(url, 'application/json', options))
    end

    # Get CSV-formatted data from the given URL
    def get_csv(url, options = {})
      get(url, 'text/csv', options)
    end

    # Get the content from the given URL, using the given content type
    def get(url, content_type, options = {}) # rubocop:disable Metrics/AbcSize
      conn = faraday_connection(url)

      r = conn.get do |req|
        req.headers['Accept'] = content_type if content_type
        req.headers['X-Request-ID'] = request_id if request_id
        req.params.merge! options

        request_logger.log_request(req) if request_logger.respond_to?(:log_request)
      end

      request_logger.log_response(r) if request_logger.respond_to?(:log_response)
      raise "Failed to read from #{url}: #{r.status.inspect}" unless permissible_response_code?(r)

      raise StandardError, r.body if r.status >= 400

      r.body
    end

    def service_base_url
      @base_url
    end

    def resolve(resource, options = {})
      return resource unless resource&.resolvable?

      uri = resource.uri
      uri = uri.sub(%r{https?://[^/]*}, base_url) if base_url

      json = get_json(uri, options)
      item = json['items']&.first

      ResourceWrapper.wrap_resource(item, options) if item
    end

    private

    def permissible_response_code?(response)
      permissible_response_codes.include?(response.status)
    end

    # Any 2xx code is permissible, but we also allow 404 on the assumption that
    # the response includes a JSON description of the error
    def permissible_response_codes
      (200..207).to_a.push(404)
    end

    def absolute_url?(url)
      url.start_with?(/https?:/)
    end

    def faraday_connection(url) # rubocop:disable Metrics/MethodLength
      options = {
        url: url,
        request: { params_encoder: Faraday::FlatParamsEncoder }
      }

      Faraday.new(options) do |faraday|
        faraday.request(:url_encoded)
        faraday.use FaradayMiddleware::FollowRedirects

        if rails_logging?
          faraday.use :instrumentation
          faraday.response(:logger, rails_logger, bodies: Rails.env.development?)
        end

        faraday.adapter :net_http
      end
    end

    # Return true if we should do logging for Rails. This is true iff:
    # - we are in a Rails project AND
    # - the Rails logger is defined AND
    # - we are not in production mode, OR
    # - we are in production mode, but a config option is set
    def rails_logging?
      defined?(Rails) &&
        defined?(Rails.logger) &&
        (!Rails.env.production? || rails_logging_config_setting)
    end

    # Return the value of the `sapi_client_log_api_calls` setting from the
    # Rails configuration, or false-y if that config setting is not defined
    def rails_logging_config_setting
      defined?(Rails) &&
        Rails.application.config.respond_to?(:sapi_client_log_api_calls) &&
        Rails.application.config.sapi_client_log_api_calls
    end

    def rails_logger
      rails_logging? && Rails.logger
    end

    def request_id
      defined?(JsonRailsLogger) && Thread.current[JsonRailsLogger::REQUEST_ID]
    end
  end
end
