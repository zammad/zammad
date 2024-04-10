# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Import
  module OTRS
    module QueueFactory
      extend Import::Factory

      # rubocop:disable Style/ModuleFunction
      extend self
      # rubocop:enable Style/ModuleFunction

      # We need to sort the records by name, to avoid missing parent queues.
      def pre_import_hook(records, *_args)
        records.sort_by! { |record| record['Name'] }
      end
    end
  end
end
