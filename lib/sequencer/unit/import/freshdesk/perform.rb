# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        class Perform < Sequencer::Unit::Base

          uses :resources, :object, :import_job, :dry_run, :field_map, :id_map

          def process
            resources.each do |resource|
              ::Sequencer.process("Import::Freshdesk::#{object}",
                                  parameters: {
                                    import_job: import_job,
                                    dry_run:    dry_run,
                                    resource:   resource,
                                    field_map:  field_map,
                                    id_map:     id_map,
                                  })
            end
          end
        end
      end
    end
  end
end
