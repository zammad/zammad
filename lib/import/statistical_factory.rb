module Import
  module StatisticalFactory
    include Import::Factory

    # rubocop:disable Style/ModuleFunction
    extend self

    attr_reader :statistics

    def import(records, *args)
      super
    end

    def reset_statistics
      @statistics = {
        skipped:     0,
        created:     0,
        updated:     0,
        unchanged:   0,
        failed:      0,
        deactivated: 0,
      }
    end

    def pre_import_hook(_records, *_args)
      reset_statistics if @statistics.blank?
    end

    def post_import_hook(_record, backend_instance, *_args)
      add_to_statistics(backend_instance)
    end

    def add_to_statistics(backend_instance)
      action               = backend_instance.action
      @statistics[action] += 1
    end
  end
end
