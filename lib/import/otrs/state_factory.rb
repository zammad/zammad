module Import
  module OTRS
    module StateFactory
      extend Import::TransactionFactory

      # rubocop:disable Style/ModuleFunction
      extend self

      def pre_import_hook(_records)
        backup
      end

      def backup
        # rename states to handle not uniq issues
        ::Ticket::State.all.each { |state|
          state.name = state.name + '_tmp'
          state.save
        }
      end
    end
  end
end
