class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module ExternalSync
            class Create < Sequencer::Unit::Base
              prepend ::Sequencer::Unit::Import::Common::Model::Mixin::SkipOnSkippedInstance

              uses :instance, :instance_action, :remote_id, :dry_run, :external_sync_source, :model_class

              def process
                return if dry_run
                return if instance_action != :created

                ::ExternalSync.create(
                  source:    external_sync_source,
                  source_id: remote_id,
                  object:    model_class.name,
                  o_id:      instance.id
                )
              end
            end
          end
        end
      end
    end
  end
end
