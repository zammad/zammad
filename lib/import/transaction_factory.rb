# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Import
  module TransactionFactory
    include Import::BaseFactory

    # rubocop:disable Style/ModuleFunction
    extend self

    def import(records, *)
      ActiveRecord::Base.transaction do
        import_action(records, *)
      end
    end
  end
end
