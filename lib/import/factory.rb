module Import
  module Factory
    include Import::BaseFactory

    # rubocop:disable Style/ModuleFunction
    extend self

    def import(records)
      pre_import_hook(records)
      records.each do |record|
        next if skip?(record)
        backend_class(record).new(record)
      end
    end
  end
end
