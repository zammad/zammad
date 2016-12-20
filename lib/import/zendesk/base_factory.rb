module Import
  module Zendesk
    module BaseFactory
      include Import::Factory

      # rubocop:disable Style/ModuleFunction
      extend self

      private

      def import_loop(records, *_args, &import_block)
        records.all!(&import_block)
      end
    end
  end
end
