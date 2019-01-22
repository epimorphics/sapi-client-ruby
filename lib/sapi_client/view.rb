# frozen-string-literal: true

module SapiClient
  # Encapsulates a view of a Sapi-NT endpoint, which tells us information about
  # the item data that is going to be returned
  class View
    def initialize(specification)
      @specification = specification
    end

    attr_reader :specification

    def name
      specification['name']
    end

    def view_specification
      specification['view']
    end

    def resource_type
      view_specification
        &.[]('class')
        &.sub(/^[^:]*:/, '')
    end
  end
end
