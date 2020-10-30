# frozen-string-literal: true

module SapiClient
  # Encapsulates a set of values from a given endpoint, conditioned by various
  # parameters including offset and limit, search term and other restrictions.
  # In particular, instances of this class can be used to encapsulate an endpoint
  # to use with paging controls such as Pagy
  class EndpointValues
    # Create a lazily-evaluated collection of values from the named endpoint
    # on the given instance.
    # @param instance The Sapi instance to query
    # @param endpoint_name The name of the endpoint method to invoke on instance
    # @param params Optional hash of option params to pass to the endpoint call
    def initialize(instance, endpoint_name, params = {})
      @instance = instance
      @endpoint_name = endpoint_name
      @params = params
    end

    attr_reader :instance, :endpoint_name, :params

    # Set the limit on the number of items to retrieve
    def limit(limit)
      params[:_limit] = limit
      self
    end

    # Set the offset on the items to retrieve
    def offset(offset)
      params[:_offset] = offset
      self
    end

    # Set the sort key
    def sort(sort_key)
      params[:_sort] = sort_key
      self
    end

    # Materialise the values of this endpoint, by invoking the endpoint method
    # of the instance, passing the stored params
    def to_a
      instance.send(endpoint_name, params)
    end
  end
end
