class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module ExternalSync
            class Lookup < Sequencer::Unit::Base
              include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure
              prepend ::Sequencer::Unit::Import::Common::Model::Mixin::SkipOnSkippedInstance

              uses :remote_id, :model_class, :external_sync_source
              provides :instance

              def process
                synced_instance = ::ExternalSync.find_by(
                  source:    external_sync_source,
                  source_id: remote_id,
                  object:    model_class.name,
                )
                return if !synced_instance

                state.provide(:instance) do
                  model_class.find(synced_instance.o_id)
                end
              rescue => e
                handle_failure(e)
              end
            end
          end
        end
      end
    end
  end
end
