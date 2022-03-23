# frozen_string_literal: true

module SapiClient
  # A registry of views that are defined anywhere in a SapiNT application
  # This registry uses an instance variable in class scope to provide a single
  # shared registration space for all currently defined SapiNT endpoints and
  # endpoint-groups. This allows an endpoint in one group to cross-reference
  # (by name) a view defined in a different group
  class ViewRegistry
    @registry = {}

    def self.register(view)
      registry[view.name] = view
    end

    def self.named_view(view_name)
      registry[view_name]
    end

    def self.registry
      instance_variable_get(:@registry)
    end
  end
end
