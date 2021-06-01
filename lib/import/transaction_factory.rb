# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module TransactionFactory
    include Import::BaseFactory

    # rubocop:disable Style/ModuleFunction
    extend self

    def import(records, *args)
      ActiveRecord::Base.transaction do
        import_action(records, *args)
      end
    end
  end
end
