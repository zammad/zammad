# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Import
  module Factory
    include Import::BaseFactory

    # rubocop:disable Style/ModuleFunction
    extend self
    alias import import_action
  end
end
