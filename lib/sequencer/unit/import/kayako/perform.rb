# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Perform < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_action :skipped, :failed

  uses :resources, :object, :import_job, :dry_run, :field_map, :id_map, :default_language
  optional :instance

  def process
    resources.each do |resource|
      ::Sequencer.process("Import::Kayako::#{object}",
                          parameters: {
                            import_job:       import_job,
                            dry_run:          dry_run,
                            resource:         resource,
                            default_language: default_language,
                            field_map:        field_map,
                            id_map:           id_map,
                            instance:         instance,
                          })
    end
  end
end
