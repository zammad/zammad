# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Perform < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_action :skipped, :failed

  uses :resources, :object, :import_job, :dry_run, :field_map, :id_map, :time_entry_available

  def process
    resources.each do |resource|
      ::Sequencer.process("Import::Freshdesk::#{object}",
                          parameters: {
                            import_job:           import_job,
                            dry_run:              dry_run,
                            resource:             resource,
                            field_map:            field_map,
                            id_map:               id_map,
                            time_entry_available: time_entry_available,
                          })
    end
  end
end
