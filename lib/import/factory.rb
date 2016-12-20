module Import
  module Factory
    include Import::BaseFactory

    # rubocop:disable Style/ModuleFunction
    extend self
    alias import import_action
  end
end
