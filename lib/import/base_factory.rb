module Import
  module BaseFactory

    # rubocop:disable Style/ModuleFunction
    extend self

    def import(_records)
      raise 'Missing implementation for import method for this factory'
    end

    def pre_import_hook(_records)
    end

    def backend_class(_record)
      "Import::#{module_name}".constantize
    end

    def skip?(_record)
      false
    end

    private

    def module_name
      name.to_s.sub(/Import::/, '').sub(/Factory/, '')
    end
  end
end
