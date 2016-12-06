module Import
  module TransactionFactory
    include Import::BaseFactory

    # rubocop:disable Style/ModuleFunction
    extend self

    def import(records)
      ActiveRecord::Base.transaction do
        pre_import_hook(records)
        records.each do |record|
          next if skip?(record)
          backend_class(record).new(record)
        end
      end
    end
  end
end
