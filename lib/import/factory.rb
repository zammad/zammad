# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Import
  module Factory
    include Import::BaseFactory

    extend self # rubocop:disable Style/ModuleFunction

    alias import import_action
  end
end
