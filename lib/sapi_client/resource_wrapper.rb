# frozen_string_literal: true

module SapiClient
  # Stateless class to collect together utilities for discovering the
  # appropriate wrapper class for a JSON-described RDF resource
  class ResourceWrapper
    # If there is a class constant corresponding to the given
    # resource type, then return it. Otherwise, return null
    def self.wrapper_class_constant(resource_type)
      return nil unless resource_type

      if resource_type.respond_to?(:classify)
        # if we're in Rails-land, this is a better way
        resource_type.classify.constantize
      else
        Kernel.const_get(resource_type)
      end
    rescue NameError => _e
      nil
    end

    # Normalise a type identifier - which may be a String, a Hash (possibly with
    # string or symbol keys), a SapiResource wrapping an `@id`, or some other
    # object - down to a plain String that can be used as a class-name key.
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def self.type_string(type)
      if type.is_a?(String)
        type
      elsif type.is_a?(Hash)
        (type[:@id] || type['@id'] || type[:@value] || type['@value']).to_s
      elsif type.respond_to?(:resource) && type.resource.is_a?(Hash)
        (type.resource[:@id] || type.resource['@id']).to_s
      else
        type.to_s
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def self.de_uri(maybe_uri)
      maybe_uri.to_s.sub(%r{^https?://.*/}, '').to_sym
    end

    def self.default_resource_wrapper_type
      SapiClient::SapiResource
    end

    # Find the first wrapper type for which there is an existing
    # class constant with the same name. If no such value is
    # found, return the default resource wrapper
    # rubocop:disable Metrics/MethodLength
    def self.find_wrapper_type(types)
      all_wrapped = Array(types)
                    .map { |type| wrapper_class_constant(de_uri(type)) }
                    .compact
      most_specific_wrapped = all_wrapped
                              .filter do |t|
        all_wrapped.none? do |a|
          t != a && a.respond_to?(:ancestors) && a.ancestors.include?(t)
        end
      end
      return most_specific_wrapped[0] unless most_specific_wrapped.empty?

      default_resource_wrapper_type
    end
    # rubocop:enable Metrics/MethodLength

    # Return the wrapper class for the given resource. If the
    # `options` specifies the wrapper class, then use that.
    # Otherwise, use the first of the resource's
    def self.wrap_resource(resource, options = {})
      types = options[:wrapper]
      types ||= resource.types if resource.respond_to?(:types)
      types ||= resource['type'] if resource.respond_to?(:[])

      wrapper = find_wrapper_type(types)

      wrapper ? wrapper.new(resource) : resource
    end
  end
end
