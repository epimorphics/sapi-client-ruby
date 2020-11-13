# frozen_string_literal: true

module SapiClient
  # Scheme properties for built-in default SKOS hierarchy scheme
  SKOS_SCHEME = OpenStruct.new(
    root_property: 'topConceptOf',
    parent_property: 'broader',
    sort_properties: %w[notation prefLabel]
  ).freeze

  # Encapsulates a resource hierarchy comprised of a set of
  # SapiNT resources, arranged according to parent/child
  # relationships
  class Hierarchy
    attr_reader :resources

    def initialize(resources, scheme)
      @resources = resources.map { |resource| HierarchyResource.new(resource) }
      @scheme = scheme
    end

    # Return true if this hierarchy is using the default SKOS scheme
    def skos?
      @scheme == :skos
    end

    # Return the hierarchy scheme definition
    def scheme
      skos? ? SKOS_SCHEME : @scheme
    end

    # Return the roots of the hierarchy, as `HierarchyResource` objects and
    # sorted according to the scheme ordering property (default is `prefLabel`)
    def roots
      return @roots if @roots

      rts = resources.filter do |resource|
        resource.path_first(scheme.root_property)
      end

      build_hierarchy(copy_array(rts), resources)

      @roots = scheme_sort(rts)
    end

    # Traverse the hierarchy in either `:depth_first` or ``:breadth_first` order.
    # Yield to an associated block at each node.
    def traverse(order)
      queue = copy_array(roots)

      until queue.empty?
        head = queue.shift
        children = scheme_sort(head.children)
        queue = accumulate_children(queue, children, order)

        yield(head)
      end
    end

    private

    def scheme_sort(resources)
      resources.sort do |resource0, resource1|
        keys0 = scheme.sort_properties.map { |p| resource0.path_first(p) }
        keys1 = scheme.sort_properties.map { |p| resource1.path_first(p) }

        key0 = keys0.compact.first
        key1 = keys1.compact.first

        key0 <=> key1
      end
    end

    def build_hierarchy(queue, resources)
      until queue.empty?
        head = queue.shift

        resources.each do |resource|
          if child_of?(head, resource)
            queue << resource
            head.add_child(resource)
          end
        end
      end
    end

    def child_of?(parent, child)
      parents = Array(child.path_all(scheme.parent_property))
      parents.map(&:uri).include?(parent.uri)
    end

    def accumulate_children(queue, children, order)
      if order == :depth_first
        children + queue
      else
        queue + children
      end
    end

    def copy_array(arr)
      arr.slice(0..-1)
    end
  end
end
