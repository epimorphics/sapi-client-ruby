# frozen-string-literal: true

require 'logger'
require 'byebug'

module SapiClient
  # Denotes a particular instance of a Sapi-NT API. The instance has the basic
  # capability of invoking a generic endpoint by URL, and we the augment this
  # instance by generating methods that can be used to invoke endpoints based
  # on the application specification.
  class Instance
    def get_items(url, options = {})
      wrapper = options.delete(:wrapper)
      raise(SapiClient::Error, "Unexpected relative URL #{url}") unless absolute_url?(url)

      json = get_json(url, options)
      items = json['error'] ? [json] : json['items'] || []

      wrapper ? items.map { |item| wrapper.new(item) } : items
    end

    # Get parsed JSON from the given URL
    def get_json(url, options = {}) # rubocop:disable Metrics/MethodLength
      conn = faraday_connection(url)

      begin
        r = conn.get do |req|
          req.headers['Accept'] = 'application/json'
          req.params.merge! options
        end

        unless permissible_response_code?(r)
          STDERR.puts r.body
          raise "Failed to read from #{url}: #{r.status.inspect}"
        end

        JSON.parse(r.body)
      end
    end

    def service_base_url
      @base_url
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

    def faraday_connection(url)
      Faraday.new(url: url) do |faraday|
        faraday.request :url_encoded
        faraday.use FaradayMiddleware::FollowRedirects
        faraday.response(:logger, Rails.logger) if defined?(Rails) && defined?(Rails.logger)

        # faraday.response(:logger, ::Logger.new(STDOUT), bodies: true)
        faraday.adapter :net_http
      end
    end
  end
end
