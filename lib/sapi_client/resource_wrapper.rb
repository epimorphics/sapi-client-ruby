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

    def self.de_uri(maybe_uri)
      maybe_uri.to_s.sub(%r{^https?://.*/}, '').to_sym
    end

    def self.default_resource_wrapper_type
      SapiClient::SapiResource
    end

    # Find the first wrapper type for which there is an existing
    # class constant with the same name. If no such value is
    # found, return the default resource wrapper
    def self.find_wrapper_type(types)
      Array(types).each do |type|
        wrapper = wrapper_class_constant(de_uri(type))
        return wrapper if wrapper
      end

      default_resource_wrapper_type
    end

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
