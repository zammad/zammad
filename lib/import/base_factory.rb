# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Import
  module BaseFactory
    extend self

    def import_action(records, *)
      pre_import_hook(records, *)
      import_loop(records, *) do |record|
        next if skip?(record, *)

        backend_instance = create_instance(record, *)
        post_import_hook(record, backend_instance, *)
      end
    end

    def import(_records, *)
      raise 'Missing import method implementation for this factory'
    end

    def pre_import_hook(_records, *); end

    def post_import_hook(_record, _backend_instance, *); end

    def backend_class(_record, *)
      "Import::#{module_name}".constantize
    end

    def skip?(_record, *)
      false
    end

    private

    def create_instance(record, *)
      backend_class(record, *).new(record, *)
    end

    def import_loop(records, *, &)
      records.each(&)
    end

    def module_name
      name.to_s.sub(%r{Import::}, '').sub(%r{Factory}, '')
    end
  end
end
