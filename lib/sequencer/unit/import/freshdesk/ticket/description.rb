# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Ticket
          class Description < Sequencer::Unit::Import::Freshdesk::SubSequence::Generic
            prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

            skip_action :skipped, :failed

            uses :dry_run, :import_job, :resource, :field_map, :id_map

            def process
              ::Sequencer.process('Import::Freshdesk::Description',
                                  parameters: {
                                    import_job: import_job,
                                    dry_run:    dry_run,
                                    field_map:  field_map,
                                    id_map:     id_map,
                                    resource:   resource,
                                  })
            end
          end
        end
      end
    end
  end
end
