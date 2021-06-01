# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module Factory
    include Import::BaseFactory

    # rubocop:disable Style/ModuleFunction
    extend self
    alias import import_action
  end
end
