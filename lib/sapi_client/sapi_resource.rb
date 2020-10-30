# frozen-string-literal: true

module SapiClient
  # Encapsulates a JSON-LD -style resource that we get back from a Sapi-NT endpoint,
  # providing a convenience API for accessing the contents of the resource.
  # Some common attributes, such as name and URI are directly supported, as are
  # generic methods for converting messages to JSON properties, and for traversing
  # path expressions.
  # Commonly, this class will be the base class for creating domain-specific
  # model classes to encapsulate particular API values.
  class SapiResource # rubocop:disable Metrics/ClassLength
    # Create a new Sapi Resource, wrapping an existing value. The possible values
    # for `resource` are:
    # - a hash of values; hash keys will be transformed to symbols
    # - an existing SapiResource object, which will create a shallow copy of the resource
    # - a String, which will be assumed to be the URI of the resource
    def initialize(resource)
      @resource = as_resource(resource)
    end

    attr_reader :resource

    def equal?(other)
      other.respond_to?(:identity_value) && identity_value.equal?(other.identity_value)
    end

    def hash
      identity_value.hash
    end

    def identity_value
      resource? ? uri : value
    end

    # Return the first value along the given path for this object
    def path_first(path)
      terminal = path_segments(path)
                 .reduce(resource) do |hsh, segment|
                   hash_with_symbol_keys(pick_first(hsh[segment])) if hsh&.key?(segment)
                 end

      terminal && wrap_term(terminal)
    end
    alias [] path_first

    # Return all values along the given path for this object
    def path_all(path)
      path_segments(path).reduce([self]) do |resources, segment|
        resources.map { |value| sapi_resource?(value) ? value.resource[segment] : nil }
                 .flatten
                 .compact
                 .map { |value| wrap_resource(value) }
      end
    end

    # Return true if this object denotes an RDF resource. Given that some resources may
    # not have URIs (i.e. bnodes), being a resource is equivalent to not being a value
    def resource?
      !value?
    end

    # A wrapped JSON-LD value has an `@value` property
    # @return The `@value` of this object, if defined
    def value
      resource[:'@value']
    end
    alias value? value

    def value_type
      value? && resource[:'@type']
    end
    alias typed_value? value_type

    def value_lang
      value? && resource[:'@language']
    end
    alias lang_tagged_value? value_lang

    def uri
      resource[:'@id']
    end
    alias named_resource? uri

    def uri_slug
      uri&.match(%r{\A.*[/#]([^#/]+)\Z})&.[](1)
    end

    # @return An array of all of the type (i.e. rdf:type) values for this resource, or nil
    def types
      path_all(:type)
    end

    # @return True if this resource has the given URI among its types
    def type?(uri)
      type_uris = types&.map { |typ| typ.is_a?(String) ? typ : typ['@id'] }
      type_uris&.include?(uri)
    end

    # Return the value of the given path. If no path is given, return the value
    # of self. The value is determined as the `@value` if the terminal result is
    # wrapped literal, or the terminal value otherwise.
    # @see path_first
    def value_of(path = nil)
      val = path ? self[path] : self
      val.respond_to?(:value) ? val.value : val
    end

    # @return The value of the given path, interpreted as a datetime
    def date(path = nil)
      (date = value_of(path)) && DateTime.parse(date)
    end

    # The default language is picked up from the current locale
    def default_lang
      I18n.locale
    end

    # @return The language we prefer a textual value to be in
    def lang(options = {})
      options[:lang] || default_lang.to_s
    end

    def pick_value_by_language(path, options = {})
      values = path_all(path)
      lang_select(values, lang(options))
    end

    def label(options = {})
      pick_value_by_language(:label, options)
    end

    def name(options = {})
      pick_value_by_language(:name, options)
    end

    def respond_to_missing?(property, _include_private = false) # rubocop:disable Lint/MissingSuper
      resource.key?(property)
    end

    def method_missing(property, *_args)
      resource.key?(property) ? self[property] : super
    end

    def []=(path, value)
      prefix = path_segments(path)
      property = prefix.pop

      target = prefix.reduce(resource) { |res, segment| res[segment] } # rubocop:disable Lint/UnmodifiedReduceAccumulator
      target[property] = value
    end

    # Return true just in case this is a resource with a URI but no other
    # properties, and so can be meaninfully resolved
    def resolvable?
      resource.keys == [:'@id']
    end

    private

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def lang_select(values, preferred_lang)
      preferred_term = nil
      preferred_term_lang = false

      values.each do |val|
        if sapi_resource?(val)
          if preferred_lang && val.value_lang == preferred_lang
            # found the preferred language term
            preferred_term = val.value_of
            preferred_term_lang = true
          elsif !preferred_term_lang && !preferred_lang && val.value_lang == default_lang
            # we don't have a preferred lang term yet, but this value is in the default lang
            preferred_term = val.value_of
          elsif !preferred_term && !val.value_lang
            # we don't have a preferred term yet, and this value is un-tagged
            preferred_term = val.value_of
          end
        else
          preferred_term = val.to_s
        end
      end

      preferred_term
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    # Return the given value as an un-wrapped resource. A Hash given to this
    # method will have its keys transformed to symbols.
    def as_resource(res)
      if res.is_a?(SapiResource) # rubocop:disable Style/CaseLikeIf
        res.resource.clone
      elsif res.is_a?(Hash)
        hash_with_symbol_keys(res)
      else
        { '@id': res.to_s }
      end
    end

    # Return the given path as an array of path segments
    def path_segments(path)
      path.to_s.split('.').map(&:to_sym)
    end

    # If `value` is an un-wrapped resource (i.e. a Hash), wrap is as a SapiResource
    def wrap_resource(value)
      value.is_a?(Hash) ? SapiResource.new(value) : value
    end

    def value_term?(term)
      term.is_a?(Hash) && term.key?(:'@value')
    end

    def wrap_term(term)
      value_term?(term) ? term[:'@value'] : wrap_resource(term)
    end

    # When given an array of choices, pick the first
    def pick_first(value)
      value.is_a?(Array) ? value.first : value
    end

    def sapi_resource?(value)
      value.is_a?(SapiClient::SapiResource)
    end

    def hash_with_symbol_keys(hsh)
      return hsh unless hsh.is_a?(Hash)

      hsh.transform_keys(&:to_sym)
    end
  end
end
