# frozen_string_literal: true

module SapiClient
  # A hierarchy resource is simply a node in some hierarchy,
  # where any node can have zero or more child resources, and
  # zero or one parent
  class HierarchyResource < SapiResource
    attr_reader :children, :parent

    def initialize(resource)
      super(resource)
      @children = []
    end

    def parent=(resource, add_reciprocal: true)
      @parent = resource
      resource.add_child(self, add_reciprocal: false) if add_reciprocal
    end

    def add_child(resource, add_reciprocal: true)
      @children.push(resource)
      resource.send(:parent=, self, add_reciprocal: false) if add_reciprocal
    end

    def each_child(&block)
      children.each(&block)
    end
  end
end
