# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module BaseFactory
    extend self

    def import_action(records, *args)
      pre_import_hook(records, *args)
      import_loop(records, *args) do |record|
        next if skip?(record, *args)

        backend_instance = create_instance(record, *args)
        post_import_hook(record, backend_instance, *args)
      end
    end

    def import(_records, *_args)
      raise 'Missing import method implementation for this factory'
    end

    def pre_import_hook(_records, *args); end

    def post_import_hook(_record, _backend_instance, *args); end

    def backend_class(_record, *_args)
      "Import::#{module_name}".constantize
    end

    def skip?(_record, *_args)
      false
    end

    private

    def create_instance(record, *args)
      backend_class(record, *args).new(record, *args)
    end

    def import_loop(records, *_args, &import_block)
      records.each(&import_block)
    end

    def module_name
      name.to_s.sub(%r{Import::}, '').sub(%r{Factory}, '')
    end
  end
end
